# app/controllers/api/v1/appointment_types_controller.rb
module Api
  module V1
    class AppointmentTypesController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show]

      def index
        appointment_types = AppointmentType.all
        render json: appointment_types.map { |type| type_to_camel(type) }, status: :ok
      end

      def show
        type = AppointmentType.find(params[:id])
        render json: type_to_camel(type), status: :ok
      end

      def create
        return not_admin unless current_user.admin?

        type = AppointmentType.new(appointment_type_params)
        if type.save
          render json: type_to_camel(type), status: :created
        else
          render json: { errors: type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        return not_admin unless current_user.admin?

        type = AppointmentType.find(params[:id])
        if type.update(appointment_type_params)
          render json: type_to_camel(type), status: :ok
        else
          render json: { errors: type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        return not_admin unless current_user.admin?

        type = AppointmentType.find(params[:id])
        type.destroy
        render json: { message: "Appointment type removed" }, status: :ok
      end

      private

      def appointment_type_params
        # Now includes :duration
        params.require(:appointment_type).permit(:name, :description, :duration)
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end

      def type_to_camel(type)
        {
          id: type.id,
          name: type.name,
          description: type.description,
          duration: type.duration,
          createdAt: type.created_at.iso8601,
          updatedAt: type.updated_at.iso8601
        }
      end
    end
  end
end
