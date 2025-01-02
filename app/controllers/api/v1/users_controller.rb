# app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      # GET /api/v1/users
      # Admin-only: list all users
      def index
        return not_admin unless current_user.admin?

        users = User.all.order(:id)
        render json: users.map { |u| user_to_camel(u) }, status: :ok
      end

      # POST /api/v1/users
      def create
        user = User.new(user_params_for_create)

        if user.save
          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/current
      # Updates the current user’s profile (first_name, last_name, phone, email).
      def current
        unless @current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
          return
        end

        if @current_user.update(user_update_params)
          render json: user_to_camel(@current_user), status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id/promote
      # Admin-only: change a user’s role to "admin"
      def promote
        return not_admin unless current_user.admin?

        user = User.find(params[:id])
        # Optionally, check if user.role is already "admin"
        if user.update(role: 'admin')
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params_for_create
        # By default, new signups have role="user" UNLESS current_user is admin and role param=admin
        attrs = params.require(:user).permit(
          :email, :password, :phone, :provider_name,
          :policy_number, :plan_type, :first_name,
          :last_name, :role
        )

        # Force role to "user" if the request isn't from an admin or didn’t explicitly set role=admin
        if !current_user&.admin? || attrs[:role] != 'admin'
          attrs[:role] = 'user'
        end

        attrs
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
          insuranceInfo: u.provider_name ? {
            providerName: u.provider_name,
            policyNumber: u.policy_number,
            planType: u.plan_type
          } : nil
        }
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
