# File: app/controllers/api/v1/signups_controller.rb
module Api
  module V1
    class SignupsController < ApplicationController
      # Or inherit from BaseController if you prefer, but ensure we do NOT run authenticate_user!
      # If you do have a BaseController that *always* tries to authenticate, you can do this:
      #
      #   class SignupsController < BaseController
      #     skip_before_action :authenticate_user!, only: [:create]
      #     ...
      #

      # POST /api/v1/signup
      def create
        user_params = params.require(:user).permit(
          :email,
          :password,
          :first_name,
          :last_name,
          :phone,
          :role
        )

        # Force role='user' if you want to ensure no one can self-sign-up as admin:
        user_params[:role] ||= 'user'
        if user_params[:role] == 'admin'
          user_params[:role] = 'user'
        end

        user = User.new(user_params)

        if user.save
          # Generate a JWT token for immediate login
          token = JWT.encode(
            { user_id: user.id },
            Rails.application.credentials.secret_key_base
          )

          render json: { jwt: token, user: camelize_user(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def camelize_user(u)
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
    end
  end
end
