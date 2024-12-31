# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        user = User.new(user_params)

        if user.save
          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(
          :email,
          :password,
          :phone,
          :provider_name,
          :policy_number,
          :plan_type
        )
      end
    end
  end
end
