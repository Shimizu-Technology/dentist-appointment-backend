# File: app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < BaseController
      # GET /api/v1/users => admin only
      def index
        return not_admin unless current_user.admin?

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

      # POST /api/v1/users => admin create user
      def create
        return not_admin unless current_user.admin?
        admin_create_user
      end

      # GET /api/v1/users/:id => admin only
      def show
        return not_admin unless current_user.admin?

        user = User.find_by(id: params[:id])
        if user.nil?
          return render json: { error: 'User not found' }, status: :not_found
        end

        render json: { user: user_to_camel(user) }, status: :ok
      end

      # GET or PATCH /api/v1/users/current => normal user’s own data
      #
      #   GET   => return current_user’s data
      #   PATCH => update current_user’s data
      #
      def current
        unless current_user
          return render json: { error: 'Unauthorized' }, status: :unauthorized
        end

        if request.get?
          # === GET => just show user
          render json: { user: user_to_camel(current_user) }, status: :ok

        elsif request.patch?
          # === PATCH => update user
          permitted_params = user_update_params

          if current_user.update(permitted_params)
            render json: user_to_camel(current_user), status: :ok
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end

        else
          # If some other method => respond 405
          head :method_not_allowed
        end
      end

      # PATCH /api/v1/users/:id/promote => admin only
      def promote
        return not_admin unless current_user.admin?

        user = User.find(params[:id])
        if user.update(role: 'admin')
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/search?q=...
      def search
        return not_admin unless current_user.admin?

        query    = params[:q].to_s.strip.downcase
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        if query.blank?
          return render json: empty_pagination(per_page), status: :ok
        end

        base_scope = User.where(
          "LOWER(first_name) LIKE :s
           OR LOWER(last_name) LIKE :s
           OR LOWER(email) LIKE :s
           OR LOWER(first_name || ' ' || last_name) LIKE :s",
          s: "%#{query}%"
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

      # PATCH /api/v1/users/:id => admin only
      def update
        return not_admin unless current_user.admin?

        user = User.find(params[:id])
        if user.update(user_params_for_admin_update)
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id => admin only
      def destroy
        return not_admin unless current_user.admin?

        user = User.find(params[:id])
        user.destroy
        render json: { message: 'User deleted successfully' }, status: :ok
      end

      # PATCH /api/v1/users/:id/resend_invitation => admin only
      def resend_invitation
        return not_admin unless current_user.admin?

        user = User.find(params[:id])

        if user.phone_only? || user.email.blank?
          return render json: {
            error: 'User has no email or is phone-only. Cannot resend invitation.'
          }, status: :unprocessable_entity
        end

        # If user has already completed their invitation
        if user.invitation_token.blank? && user.force_password_reset == false
          return render json: {
            error: 'User has already completed their invitation.'
          }, status: :unprocessable_entity
        end

        user.prepare_invitation_token
        user.save!

        AdminUserMailer.invitation_email(user).deliver_later

        render json: {
          message: "Invitation re-sent to #{user.email}",
          user: user_to_camel(user)
        }, status: :ok
      end

      private

      # Called from POST /api/v1/users
      def admin_create_user
        user = User.new(user_params_for_admin_create)
        user.role ||= 'user'

        if !user.phone_only? && user.email.present?
          user.prepare_invitation_token
        end

        if user.save
          # If user has an email => send invitation
          if user.email.present? && !user.phone_only?
            AdminUserMailer.invitation_email(user).deliver_later
          end

          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def user_params_for_admin_create
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role,
          :is_dependent,
          :parent_user_id,
          :date_of_birth
        )
      end

      def user_params_for_admin_update
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role,
          :is_dependent,
          :parent_user_id,
          :date_of_birth
        )
      end

      #
      # For normal user updating themselves (via PATCH /api/v1/users/current)
      #
      def user_update_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :phone,
          :email,
          :provider_name,
          :policy_number,
          :plan_type,
          :date_of_birth
        )
      end

      def user_to_camel(u)
        {
          id:              u.id,
          email:           u.email,
          role:            u.role,
          firstName:       u.first_name,
          lastName:        u.last_name,
          phone:           u.phone,
          isDependent:     u.is_dependent,
          parentUserId:    u.parent_user_id,
          # Convert to "YYYY-MM-DD" if present
          dateOfBirth:     u.date_of_birth&.strftime('%Y-%m-%d'),
          insuranceInfo: (u.provider_name.present? ?
            {
              providerName:  u.provider_name,
              policyNumber:  u.policy_number,
              planType:      u.plan_type
            } : nil),
          forcePasswordReset: u.force_password_reset,
          invitationToken:    u.invitation_token
        }
      end

      def not_admin
        render json: { error: 'Not authorized (admin only)' }, status: :forbidden
      end

      def empty_pagination(per_page)
        {
          users: [],
          meta: {
            currentPage: 1,
            totalPages:  1,
            totalCount:  0,
            perPage:     per_page
          }
        }
      end
    end
  end
end
