# frozen_string_literal: true

module Api
  module V1
    class AppointmentTypesController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show]

      # GET /api/v1/appointment_types
      def index
        appointment_types = AppointmentType.all
        render json: appointment_types, status: :ok
      end

      # GET /api/v1/appointment_types/:id
      def show
        type = AppointmentType.find(params[:id])
        render json: type, status: :ok
      end

      # POST /api/v1/appointment_types
      # Typically only admins can create a new appointment type
      def create
        return not_admin unless current_user.admin?

        type = AppointmentType.new(appointment_type_params)
        if type.save
          render json: type, status: :created
        else
          render json: { errors: type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/appointment_types/:id
      def update
        return not_admin unless current_user.admin?

        type = AppointmentType.find(params[:id])
        if type.update(appointment_type_params)
          render json: type, status: :ok
        else
          render json: { errors: type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/appointment_types/:id
      def destroy
        return not_admin unless current_user.admin?

        type = AppointmentType.find(params[:id])
        type.destroy
        render json: { message: "Appointment type removed" }, status: :ok
      end

      private

      def appointment_type_params
        params.require(:appointment_type).permit(:name, :description)
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end
    end
  end
end
