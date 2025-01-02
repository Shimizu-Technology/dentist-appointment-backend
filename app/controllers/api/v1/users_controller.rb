# File: app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate_user!, only: [:create]

      # GET /api/v1/users
      # Admin-only: list all users
      def index
        return not_admin unless current_user.admin?

        # Parse pagination params (defaults to page=1, per_page=10)
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        # Order by ID for consistency
        base_scope = User.order(:id)

        # Use Kaminari’s .page(x).per(y) to paginate
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

      # POST /api/v1/users
      def create
        user = User.new(user_params_for_create)
        if user.save
          token = JWT.encode({ user_id: user.id }, Rails.application.credentials.secret_key_base)
          render json: { jwt: token, user: user_to_camel(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/current
      def current
        unless @current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
          return
        end

        if @current_user.update(user_update_params)
          render json: user_to_camel(@current_user), status: :ok
        else
          render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/users/:id/promote
      def promote
        return not_admin unless current_user.admin?

        user = User.find(params[:id])
        if user.update(role: 'admin')
          render json: user_to_camel(user), status: :ok
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def search
        return not_admin unless current_user.admin?

        query = params[:q].to_s.strip.downcase
        if query.blank?
          render json: { users: [] }, status: :ok
          return
        end

        # Simple approach: search first_name, last_name, or email
        # For large data sets, consider PG trigram indexes or separate approach
        matching_users = User.where(
          "LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%"
        ).order(:id).limit(20)

        render json: {
          users: matching_users.map { |u| user_to_camel(u) }
        }, status: :ok
      end

      private

      def user_params_for_create
        attrs = params.require(:user).permit(
          :email, :password, :phone, :provider_name,
          :policy_number, :plan_type, :first_name,
          :last_name, :role
        )
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

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
