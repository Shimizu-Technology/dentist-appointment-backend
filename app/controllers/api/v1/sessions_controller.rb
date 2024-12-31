module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      def create
        user = User.find_by(email: params[:email])
        if user && user.valid_password?(params[:password]) # Devise method
          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user }, status: :created
        else
          render json: { error: 'Invalid email or password' }, status: :unauthorized
        end
      end
    end
  end
end
