# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      respond_to :json

      before_action :authenticate_user!

      # Custom JWT-based authentication for API calls
      def authenticate_user!
        header = request.headers['Authorization']
        token = header.split(' ').last if header.present?
        return unauthenticated! unless token

        begin
          decoded = JWT.decode(token, Rails.application.credentials.secret_key_base).first
          @current_user = User.find(decoded['user_id'])
        rescue ActiveRecord::RecordNotFound, JWT::DecodeError
          unauthenticated!
        end
      end

      def current_user
        @current_user
      end

      private

      def unauthenticated!
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end
