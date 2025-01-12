# File: app/controllers/api/v1/admin/children_controller.rb
module Api
  module V1
    module Admin
      class ChildrenController < BaseController
        before_action :authenticate_user!
        before_action :require_admin!

        # GET /api/v1/admin/children?parent_user_id=XX
        def index
          # if no parent_user_id, you might return all child users or an error.
          if params[:parent_user_id].blank?
            return render json: { error: 'Missing parent_user_id param' }, status: :unprocessable_entity
          end

          parent_id = params[:parent_user_id].to_i
          # Find all users where parent_user_id == parent_id
          children = User.where(parent_user_id: parent_id, is_dependent: true).order(:id)

          render json: children.map { |u| user_to_camel(u) }, status: :ok
        end

        # POST /api/v1/admin/children
        # Usually you might not need this if you rely on POST /api/v1/users with is_dependent + parent_user_id,
        # but if you prefer a dedicated route, handle it here. We'll keep it for completeness.
        def create
          child_user = User.new(child_user_params)
          child_user.is_dependent = true   # Force dependent
          # child_user.role = 'user' or 'phone_only' => up to you
          child_user.role ||= 'phone_only'

          if child_user.save
            render json: user_to_camel(child_user), status: :created
          else
            render json: { errors: child_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/admin/children/:id
        # This is the new action that allows admin to edit an existing child user
        def update
          child_user = User.find_by(id: params[:id], is_dependent: true)
          return render_not_found unless child_user

          # Possibly allow changing parent_user_id if admin wants to reassign the child to a different parent
          if child_user.update(child_user_params)
            render json: user_to_camel(child_user), status: :ok
          else
            render json: { errors: child_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/children/:id
        def destroy
          child_user = User.find_by(id: params[:id], is_dependent: true)
          return render_not_found unless child_user

          child_user.destroy
          render json: { message: 'Child user deleted.' }, status: :ok
        end

        private

        def render_not_found
          render json: { error: 'Child user not found' }, status: :not_found
        end

        def require_admin!
          unless current_user.admin?
            render json: { error: 'Not authorized (admin only)' }, status: :forbidden
          end
        end

        def child_user_params
          # e.g. { user: { first_name, last_name, date_of_birth, parent_user_id, ... } }
          params.require(:user).permit(
            :first_name,
            :last_name,
            :date_of_birth,
            :parent_user_id,  # allow admin to reassign child if needed
            :phone,
            :email,
            :role
            # etc. if you want admin to edit more fields
          )
        end

        def user_to_camel(u)
          {
            id:           u.id,
            email:        u.email,
            role:         u.role,
            firstName:    u.first_name,
            lastName:     u.last_name,
            phone:        u.phone,
            isDependent:  u.is_dependent,
            parentUserId: u.parent_user_id,
            dateOfBirth:  u.date_of_birth&.strftime('%Y-%m-%d')
          }
        end
      end
    end
  end
end
