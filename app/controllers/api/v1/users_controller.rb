# File: app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < BaseController
      # Everything remains the same up top...
      # We require admin for :index, :create, :update, :destroy, :promote, :search
      # The only exception is patch /users/current => for the currently logged in user

      # GET /api/v1/users (Admin-only, paginated)
      def index
        return not_admin unless current_user&.admin?

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

      # POST /api/v1/users (Admin creation)
      def create
        return not_admin unless current_user&.admin?
        admin_create_user
      end

      # PATCH /api/v1/users/current (for user updating their own info)
      def current
        unless @current_user
          return render json: { error: 'Unauthorized' }, status: :unauthorized
        end

        if @current_user.update(user_update_params)
          render json: user_to_camel(@current_user), status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id/promote (Admin-only)
      def promote
        return not_admin unless current_user&.admin?

        user = User.find(params[:id])
        if user.update(role: 'admin')
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/search?q=...
      def search
        return not_admin unless current_user&.admin?

        query    = params[:q].to_s.strip.downcase
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        if query.blank?
          return render json: {
            users: [],
            meta: {
              currentPage: 1,
              totalPages:  1,
              totalCount:  0,
              perPage:     per_page
            }
          }, status: :ok
        end

        # Example for PostgreSQL: using (first_name || ' ' || last_name).
        # If MySQL, use CONCAT(first_name, ' ', last_name).
        base_scope = User.where("
          LOWER(first_name) LIKE :s
          OR LOWER(last_name) LIKE :s
          OR LOWER(first_name || ' ' || last_name) LIKE :s
          OR LOWER(email) LIKE :s
        ", s: "%#{query}%").order(:id)

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

      # PATCH /api/v1/users/:id (Admin-only)
      def update
        return not_admin unless current_user&.admin?

        user = User.find(params[:id])
        # e.g. user_params_for_admin_update includes phone, email, first_name, last_name, role
        if user.update(user_params_for_admin_update)
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:id (Admin-only)
      def destroy
        return not_admin unless current_user&.admin?

        user = User.find(params[:id])
        user.destroy
        render json: { message: 'User deleted successfully' }, status: :ok
      end

      private

      # ----------------------------------------------------------------
      # 1) ADMIN CREATION (invitation-based)
      # ----------------------------------------------------------------
      def admin_create_user
        user = User.new(user_params_for_admin_create)
        user.role ||= 'user'

        if !user.phone_only? && user.email.present?
          user.generate_invitation_token!
        end

        if user.save
          if user.email.present? && !user.phone_only?
            AdminUserMailer.invitation_email(user).deliver_later
          end

          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ----------------------------------------------------------------
      # PERMITTED PARAMS
      # ----------------------------------------------------------------
      def user_params_for_admin_create
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role
        )
      end

      def user_params_for_admin_update
        # Admin can update these fields
        params.require(:user).permit(
          :email,
          :phone,
          :first_name,
          :last_name,
          :role
          # Add :password if you also want admins to set/force a new password
        )
      end

      # For patch /users/current
      def user_update_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :phone,
          :email,
          :provider_name,
          :policy_number,
          :plan_type
        )
      end

      def user_to_camel(u)
        {
          id:                  u.id,
          email:               u.email,
          role:                u.role,
          firstName:           u.first_name,
          lastName:            u.last_name,
          phone:               u.phone,
          insuranceInfo: (u.provider_name ? {
            providerName:   u.provider_name,
            policyNumber:   u.policy_number,
            planType:       u.plan_type
          } : nil),
          forcePasswordReset:  u.force_password_reset,
          invitationToken:     u.invitation_token
        }
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
