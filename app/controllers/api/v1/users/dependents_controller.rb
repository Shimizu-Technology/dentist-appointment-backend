# File: app/controllers/api/v1/users/dependents_controller.rb

module Api
  module V1
    module Users
      class DependentsController < BaseController
        before_action :require_admin!

        # POST /api/v1/users/:user_id/dependents
        def create
          user = User.find(params[:user_id])
          dependent = user.dependents.new(converted_dependent_params)

          if dependent.save
            render json: dependent_to_camel(dependent), status: :created
          else
            render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # PATCH/PUT /api/v1/users/:user_id/dependents/:id
        def update
          user = User.find(params[:user_id])
          dependent = user.dependents.find(params[:id])

          if dependent.update(converted_dependent_params)
            render json: dependent_to_camel(dependent), status: :ok
          else
            render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/users/:user_id/dependents/:id
        def destroy
          user = User.find(params[:user_id])
          dependent = user.dependents.find(params[:id])
          dependent.destroy
          render json: { message: "Dependent removed" }, status: :ok
        end

        private

        def require_admin!
          unless current_user.admin?
            render json: { error: "Not authorized (admin only)" }, status: :forbidden
          end
        end

        def converted_dependent_params
          permitted = params.require(:dependent).permit(:firstName, :lastName, :dateOfBirth)
          {
            first_name:    permitted[:firstName],
            last_name:     permitted[:lastName],
            date_of_birth: permitted[:dateOfBirth],
          }
        end

        def dependent_to_camel(dep)
          {
            id:          dep.id,
            firstName:   dep.first_name,
            lastName:    dep.last_name,
            dateOfBirth: dep.date_of_birth&.strftime('%Y-%m-%d'),
            userId:      dep.user_id,
            createdAt:   dep.created_at.iso8601,
            updatedAt:   dep.updated_at.iso8601
          }
        end
      end
    end
  end
end
