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

      #
      # GET /api/v1/users/:id => admin only
      #
      def show
        return not_admin unless current_user.admin?

        user = User.find_by(id: params[:id])
        if user.nil?
          return render json: { error: 'User not found' }, status: :not_found
        end

        # Return the user object in same camel-case format as the rest
        render json: { user: user_to_camel(user) }, status: :ok
      end

      # PATCH /api/v1/users/current => user updating themselves
      def current
        return render json: { error: 'Unauthorized' }, status: :unauthorized unless current_user

        if current_user.update(user_update_params)
          render json: user_to_camel(current_user), status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
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

      private

      # Called from POST /api/v1/users
      def admin_create_user
        user = User.new(user_params_for_admin_create)
        user.role ||= 'user'

        # Possibly generate invitation if user is not phone_only and has an email
        if !user.phone_only? && user.email.present?
          user.generate_invitation_token!
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

      def user_update_params
        # For normal user updating themselves
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
          dateOfBirth:     u.date_of_birth&.strftime('%Y-%m-%d'),
          insuranceInfo: (
            u.provider_name ? {
              providerName: u.provider_name,
              policyNumber: u.policy_number,
              planType:     u.plan_type
            } : nil
          ),
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
            totalPages: 1,
            totalCount: 0,
            perPage: per_page
          }
        }
      end
    end
  end
end
