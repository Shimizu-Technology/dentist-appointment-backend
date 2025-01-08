# File: app/controllers/api/v1/invitations_controller.rb
module Api
  module V1
    class InvitationsController < BaseController
      # We skip auth here because an invited user is not logged in yet.
      skip_before_action :authenticate_user!, only: [:finish]

      # PATCH /api/v1/invitations/finish
      # Expect params: { token: "...", password: "someNewPass" }
      def finish
        user = User.find_by(invitation_token: params[:token])
        if user.nil?
          return render json: { error: 'Invalid or expired invitation token' }, status: :not_found
        end

        # Attempt to finalize
        user.finish_invitation!(params[:password])  # => custom method on the User model

        # If you want to auto-log them in, generate a JWT
        token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)

        render json: { jwt: token, user: user_to_camel(user) }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end

      private

      def user_to_camel(u)
        {
          id: u.id,
          email: u.email,
          role: u.role,
          firstName: u.first_name,
          lastName: u.last_name,
          phone: u.phone
        }
      end
    end
  end
end
