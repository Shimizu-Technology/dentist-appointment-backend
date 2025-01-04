# File: app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      # GET /api/v1/users (Admin-only, paginated)
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

      # POST /api/v1/users (Sign up; or admin can create a user)
      def create
        user = User.new(user_params_for_create)
        if user.save
          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/current (Update the currently logged-in user)
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
        return not_admin unless current_user.admin?

        user = User.find(params[:id])
        if user.update(role: 'admin')
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/search?q=...&page=...&per_page=...
      # Admin-only search by firstName, lastName, or email. Paginated.
      def search
        return not_admin unless current_user.admin?

        query    = params[:q].to_s.strip.downcase
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        if query.blank?
          # If nothing typed, return empty or you could default to all
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

        base_scope = User.where(
          "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%"
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

      private

      def user_params_for_create
        attrs = params.require(:user).permit(
          :email, :password, :phone, :provider_name,
          :policy_number, :plan_type, :first_name,
          :last_name, :role
        )
        # If non-admin tries to set role=admin, override to user
        if !current_user&.admin? || attrs[:role] != 'admin'
          attrs[:role] = 'user'
        end
        attrs
      end

      def user_update_params
        params.require(:user).permit(:first_name, :last_name, :phone, :email)
      end

      def user_to_camel(u)
        {
          id:          u.id,
          email:       u.email,
          role:        u.role,
          firstName:   u.first_name,
          lastName:    u.last_name,
          phone:       u.phone,
          insuranceInfo: u.provider_name ? {
            providerName: u.provider_name,
            policyNumber: u.policy_number,
            planType:     u.plan_type
          } : nil
        }
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
