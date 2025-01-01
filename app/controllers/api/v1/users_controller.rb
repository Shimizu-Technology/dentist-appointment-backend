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

      private

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
