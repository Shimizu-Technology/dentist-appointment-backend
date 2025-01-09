# File: app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

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
      def create
        # Build the user from params
        user = User.new(user_params_for_create)

        # If no role is passed in, default it to 'user'
        user.role ||= 'user'

        # If phone_only => no email needed, no password needed.
        # If normal user => no password is given here; we generate an invitation if they have an email
        if !user.phone_only? && user.email.present?
          user.generate_invitation_token!
        end

        # Overrule an attempt to set role=admin if not currently admin
        if !current_user&.admin? && user.role == 'admin'
          user.role = 'user'
        end

        if user.save
          # If user has an email and is not phone_only, send invitation
          if user.email.present? && !user.phone_only?
            # Our new “invitation_email” method
            AdminUserMailer.invitation_email(user).deliver_later
          end

          # Return a JWT or simply return the user.
          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/current
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

      # PATCH /api/v1/users/:id/promote
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

        base_scope = User.where(
          "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%"
        ).order(:id)

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

      def user_params_for_create
        # NOTE: We do NOT permit password here since we rely on invitation-based or phone_only approach
        # But we do allow :role, in case an admin tries to pass role=admin, which we guard above
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role
        )
      end

      # For updating the current user, we also allow insurance fields
      # (provider_name, policy_number, plan_type).
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
          id: u.id,
          email: u.email,
          role: u.role,
          firstName: u.first_name,
          lastName: u.last_name,
          phone: u.phone,
          insuranceInfo: (u.provider_name ? {
            providerName: u.provider_name,
            policyNumber: u.policy_number,
            planType:     u.plan_type
          } : nil),
          forcePasswordReset: u.force_password_reset,
          invitationToken: u.invitation_token
        }
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end

  