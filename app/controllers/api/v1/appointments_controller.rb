# app/controllers/api/v1/appointments_controller.rb
module Api
  module V1
    class AppointmentsController < BaseController
      # GET /api/v1/appointments
      def index
        if current_user.admin?
          @appointments = Appointment.all
        else
          @appointments = Appointment.where(user_id: current_user.id)
        end
        render json: @appointments, status: :ok
      end

      # POST /api/v1/appointments
      def create
        appointment = Appointment.new(appointment_params.merge(user_id: current_user.id))

        if Appointment.exists?(dentist_id: appointment.dentist_id,
                               appointment_time: appointment.appointment_time,
                               status: %w[scheduled])
          render json: { error: "This time slot is not available." }, status: :unprocessable_entity
        else
          if appointment.save
            render json: appointment, status: :created
          else
            render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
          end
        end
      end

      # GET /api/v1/appointments/:id
      def show
        appointment = Appointment.find(params[:id])
        unless current_user.admin? || appointment.user_id == current_user.id
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        render json: appointment
      end

      # PATCH/PUT /api/v1/appointments/:id
      def update
        appointment = Appointment.find(params[:id])
        unless current_user.admin? || appointment.user_id == current_user.id
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        # Check conflict only if changing dentist/time
        if appointment_params[:dentist_id].present? && appointment_params[:appointment_time].present?
          if Appointment.exists?(dentist_id: appointment_params[:dentist_id],
                                 appointment_time: appointment_params[:appointment_time],
                                 status: %w[scheduled])
            return render json: { error: "This time slot is not available." }, status: :unprocessable_entity
          end
        end

        if appointment.update(appointment_params)
          render json: appointment, status: :ok
        else
          render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/appointments/:id
      def destroy
        appointment = Appointment.find(params[:id])
        unless current_user.admin? || appointment.user_id == current_user.id
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        appointment.destroy
        render json: { message: "Appointment canceled." }, status: :ok
      end

      private

      def appointment_params
        params.require(:appointment).permit(:appointment_time, :appointment_type_id,
                                           :dentist_id, :status, :dependent_id)
      end
    end
  end
end
