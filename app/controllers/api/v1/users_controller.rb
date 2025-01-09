# File: app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < BaseController
      # By default, we do NOT skip authentication, so an admin must be logged in
      # to access these actions.

      # GET /api/v1/users (Admin-only, paginated)
      def index
        return not_admin unless current_user&.admin?

        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        base_scope = User.order(:id)
        @users = base_scope.page(page).per(per_page)

        render json: {
          users: @users.map { |u| user_to_camel(u) },
          meta: {
            currentPage: @users.current_page,
            totalPages:  @users.total_pages,
            totalCount:  @users.total_count,
            perPage:     per_page
          }
        }, status: :ok
      end

      # POST /api/v1/users
      # => Admin creation (invitation-based)
      #
      # Only an admin can create a new user here. (No password param is required,
      # because we send an invitation email if they have an email address.)
      def create
        return not_admin unless current_user&.admin?

        admin_create_user
      end

      # PATCH /api/v1/users/current
      # => Allows the *currently logged-in user* to update their own data
      def current
        unless @current_user
          return render json: { error: 'Unauthorized' }, status: :unauthorized
        end

        if @current_user.update(user_update_params)
          render json: user_to_camel(@current_user), status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id/promote  (Admin-only)
      #
      # Example usage: promote a user to admin
      def promote
        return not_admin unless current_user&.admin?

        user = User.find(params[:id])
        if user.update(role: 'admin')
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/search?q=...
      # => Admin-only search. Supports partial matching by first_name, last_name,
      #    *full_name* (first + last), and email, all in LOWER(...) for case-insensitivity.
      def search
        return not_admin unless current_user&.admin?

        query    = params[:q].to_s.strip.downcase
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        if query.blank?
          return render json: {
            users: [],
            meta: {
              currentPage: 1,
              totalPages:  1,
              totalCount:  0,
              perPage:     per_page
            }
          }, status: :ok
        end

        # Example for PostgreSQL: using (first_name || ' ' || last_name).
        # If MySQL, use CONCAT(first_name, ' ', last_name).
        base_scope = User.where("
          LOWER(first_name) LIKE :s
          OR LOWER(last_name) LIKE :s
          OR LOWER(first_name || ' ' || last_name) LIKE :s
          OR LOWER(email) LIKE :s
        ", s: "%#{query}%").order(:id)

        @users = base_scope.page(page).per(per_page)

        render json: {
          users: @users.map { |u| user_to_camel(u) },
          meta: {
            currentPage: @users.current_page,
            totalPages:  @users.total_pages,
            totalCount:  @users.total_count,
            perPage:     per_page
          }
        }, status: :ok
      end

      private

      # ----------------------------------------------------------------
      # 1) ADMIN CREATION (invitation-based)
      # ----------------------------------------------------------------
      def admin_create_user
        user = User.new(user_params_for_admin_create)
        user.role ||= 'user'

        # If user is not phone_only and has an email => generate invitation
        if !user.phone_only? && user.email.present?
          user.generate_invitation_token!
        end

        if user.save
          # Send invitation email if user has email + not phone_only
          if user.email.present? && !user.phone_only?
            AdminUserMailer.invitation_email(user).deliver_later
          end

          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ----------------------------------------------------------------
      # PERMITTED PARAMS
      # ----------------------------------------------------------------
      # For an admin creating a user: no password param => invitation-based flow
      def user_params_for_admin_create
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role
        )
      end

      # For patch /users/current (including insurance fields)
      def user_update_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :phone,
          :email,
          :provider_name,
          :policy_number,
          :plan_type
        )
      end

      def user_to_camel(u)
        {
          id:                  u.id,
          email:               u.email,
          role:                u.role,
          firstName:           u.first_name,
          lastName:            u.last_name,
          phone:               u.phone,
          insuranceInfo: (u.provider_name ? {
            providerName:   u.provider_name,
            policyNumber:   u.policy_number,
            planType:       u.plan_type
          } : nil),
          forcePasswordReset:  u.force_password_reset,
          invitationToken:     u.invitation_token
        }
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
