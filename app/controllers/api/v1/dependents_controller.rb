# File: app/controllers/api/v1/dependents_controller.rb
module Api
  module V1
    class DependentsController < BaseController
      before_action :require_admin_for_other_user!, only: [:create]

      # GET /api/v1/dependents
      # Optional ?user_id=123
      #
      # If user_id is present and current_user is admin, show that user’s dependents.
      # Otherwise, show only the current_user’s dependents (whether admin or not).
      def index
        if params[:user_id].present? && current_user.admin?
          target_user = User.find(params[:user_id])
          dependents = target_user.dependents
        else
          # Normal case => just the current_user’s own dependents
          dependents = current_user.dependents
        end

        render json: dependents.map { |dep| dependent_to_camel(dep) }, status: :ok
      end

      # POST /api/v1/dependents
      #   or /api/v1/dependents?user_id=123 for admin creating for user #123
      def create
        target_user = if current_user.admin? && params[:user_id].present?
                        User.find(params[:user_id])
                      else
                        current_user
                      end

        dependent = target_user.dependents.new(converted_dependent_params)

        if dependent.save
          render json: dependent_to_camel(dependent), status: :created
        else
          render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        render json: dependent_to_camel(dependent), status: :ok
      end

      def update
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        if dependent.update(converted_dependent_params)
          render json: dependent_to_camel(dependent), status: :ok
        else
          render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        dependent.destroy
        render json: { message: "Dependent removed" }, status: :ok
      end

      private

      # Only an admin can create dependents for another user_id;
      # a normal user can only create them for themselves.
      def require_admin_for_other_user!
        return if params[:user_id].blank? # user is creating for themselves
        return if current_user&.admin?

        render json: { error: 'Not authorized' }, status: :forbidden
      end

      def converted_dependent_params
        # Expecting { dependent: { firstName, lastName, dateOfBirth } }
        # Convert to underscore keys
        permitted = params.require(:dependent).permit(:firstName, :lastName, :dateOfBirth)
        {
          first_name:    permitted[:firstName],
          last_name:     permitted[:lastName],
          date_of_birth: permitted[:dateOfBirth]
        }
      end

      def can_manage_dependent?(dependent)
        current_user.admin? || (dependent.user_id == current_user.id)
      end

      def not_authorized
        render json: { error: 'Not authorized' }, status: :forbidden
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
