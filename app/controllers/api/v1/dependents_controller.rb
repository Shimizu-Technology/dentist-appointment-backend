# File: app/controllers/api/v1/dependents_controller.rb
module Api
  module V1
    class DependentsController < BaseController
      # GET /api/v1/dependents
      def index
        dependents = current_user.dependents
        render json: dependents.map { |dep| dependent_to_camel(dep) }, status: :ok
      end

      # POST /api/v1/dependents
      def create
        # We transform the incoming camelCase keys to underscore so that
        # the Dependent model fields get set properly.
        dependent = current_user.dependents.new(converted_dependent_params)

        if dependent.save
          render json: dependent_to_camel(dependent), status: :created
        else
          render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/dependents/:id
      def show
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)
        render json: dependent_to_camel(dependent), status: :ok
      end

      # PATCH/PUT /api/v1/dependents/:id
      def update
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        if dependent.update(converted_dependent_params)
          render json: dependent_to_camel(dependent), status: :ok
        else
          render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/dependents/:id
      def destroy
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        dependent.destroy
        render json: { message: "Dependent removed" }, status: :ok
      end

      private

      # 1) Permit the incoming camelCase keys firstName, lastName, dateOfBirth.
      # 2) Convert them to underscore keys for the actual DB columns.
      def converted_dependent_params
        permitted = params.require(:dependent).permit(:firstName, :lastName, :dateOfBirth)
        {
          first_name:    permitted[:firstName],
          last_name:     permitted[:lastName],
          date_of_birth: permitted[:dateOfBirth]
        }
      end

      def can_manage_dependent?(dependent)
        current_user.admin? || dependent.user_id == current_user.id
      end

      def not_authorized
        render json: { error: "Not authorized" }, status: :forbidden
      end

      def dependent_to_camel(dep)
        {
          id:          dep.id,
          userId:      dep.user_id,
          firstName:   dep.first_name,
          lastName:    dep.last_name,
          dateOfBirth: dep.date_of_birth&.strftime('%Y-%m-%d'),
          createdAt:   dep.created_at.iso8601,
          updatedAt:   dep.updated_at.iso8601
        }
      end
    end
  end
end
