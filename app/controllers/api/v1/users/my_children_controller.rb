# File: app/controllers/api/v1/users/my_children_controller.rb

module Api
  module V1
    module Users
      class MyChildrenController < BaseController
        before_action :authenticate_user!

        # GET /api/v1/users/my_children
        # Lists the child users for the current user
        def index
          child_users = current_user.child_users.order(:id)
          render json: child_users.map { |u| user_to_camel(u) }, status: :ok
        end

        # POST /api/v1/users/my_children
        def create
          child_user = current_user.child_users.new(child_user_params)
          child_user.is_dependent = true
          child_user.role = 'phone_only'
          child_user.email = nil
          child_user.phone = nil

          if child_user.save
            render json: user_to_camel(child_user), status: :created
          else
            render json: { errors: child_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/users/my_children/:id
        def update
          child_user = current_user.child_users.find_by(id: params[:id])
          return render json: { error: 'Not found or not authorized' }, status: :forbidden unless child_user

          if child_user.update(child_user_params)
            render json: user_to_camel(child_user), status: :ok
          else
            render json: { errors: child_user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/users/my_children/:id
        def destroy
          child_user = current_user.child_users.find_by(id: params[:id])
          return render json: { error: 'Not found or not authorized' }, status: :forbidden unless child_user

          child_user.destroy
          render json: { message: 'Child user removed.' }, status: :ok
        end

        private

        def child_user_params
          params.require(:user).permit(:first_name, :last_name, :date_of_birth)
        end

        def user_to_camel(u)
          {
            id:             u.id,
            email:          u.email,
            role:           u.role,
            firstName:      u.first_name,
            lastName:       u.last_name,
            phone:          u.phone,
            isDependent:    u.is_dependent?,
            parentUserId:   u.parent_user_id,
            dateOfBirth:    u.date_of_birth&.strftime('%Y-%m-%d'),
            forcePasswordReset: u.force_password_reset,
            invitationToken:    u.invitation_token
          }
        end
      end
    end
  end
end
