# frozen_string_literal: true

module Api
  module V1
    class DependentsController < BaseController
      # GET /api/v1/dependents
      def index
        if current_user.admin?
          # Admin can see all
          dependents = Dependent.all
        else
          # Regular user sees only their own
          dependents = current_user.dependents
        end

        render json: dependents, status: :ok
      end

      # POST /api/v1/dependents
      def create
        dependent = current_user.dependents.new(dependent_params)

        if dependent.save
          render json: dependent, status: :created
        else
          render json: { errors: dependent.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/dependents/:id
      def show
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        render json: dependent, status: :ok
      end

      # PATCH/PUT /api/v1/dependents/:id
      def update
        dependent = Dependent.find(params[:id])
        return not_authorized unless can_manage_dependent?(dependent)

        if dependent.update(dependent_params)
          render json: dependent, status: :ok
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

      def dependent_params
        params.require(:dependent).permit(:first_name, :last_name, :date_of_birth)
      end

      def can_manage_dependent?(dependent)
        current_user.admin? || dependent.user_id == current_user.id
      end

      def not_authorized
        render json: { error: "Not authorized" }, status: :forbidden
      end
    end
  end
end
