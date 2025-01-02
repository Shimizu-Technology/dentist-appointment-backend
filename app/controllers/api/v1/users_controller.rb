# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        user = User.new(user_params)

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
        unless @current_user  # from BaseController#authenticate_user!
          render json: { error: 'Unauthorized' }, status: :unauthorized
          return
        end

        if @current_user.update(user_update_params)
          render json: user_to_camel(@current_user), status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # Used when creating a new user (signup).
      def user_params
        # Permit the fields you need (including first_name, last_name, etc.)
        # Then force 'role' to 'user' with .merge(role: 'user')
        params.require(:user).permit(
          :email,
          :password,
          :phone,
          :provider_name,
          :policy_number,
          :plan_type,
          :first_name,
          :last_name
        ).merge(role: 'user')
      end

      # Used when updating an existing user
      def user_update_params
        # Let the user update these fields:
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
    end
  end
end
