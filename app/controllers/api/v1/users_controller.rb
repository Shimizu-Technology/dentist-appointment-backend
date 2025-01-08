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
        # Only an admin may set 'role' = 'admin'; a non-admin cannot do that
        # But if user is not logged in or not admin, let's allow them to create phone_only or normal
        # Adjust as needed for your security model

        # Build the user from params
        user = User.new(user_params_for_create)

        # If phone_only => no email needed, no password needed
        # If normal user => no password is given here; they get an invitation link
        # So let's generate an invitation token if the user has an email
        if !user.phone_only? && user.email.present?
          user.generate_invitation_token!  # or do it after user.save if you prefer
        end

        # Overrule an attempt to set role=admin if not currently admin
        if !current_user&.admin? && user.role == 'admin'
          user.role = 'user'
        end

        if user.save
          # Send the invitation email if user has an email and is not phone_only
          if user.email.present? && !user.phone_only?
            # Our new “invitation_email” method
            AdminUserMailer.invitation_email(user).deliver_later
          end

          # Return a JWT or simply return the user. Because admin might be creating them in an admin panel
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
        # allow phone, first_name, last_name, role, email, but no password param needed
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role
        )
      end

      def user_update_params
        params.require(:user).permit(:first_name, :last_name, :phone, :email)
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
          invitationToken: u.invitation_token  # optional if you want to see it in the response
        }
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
