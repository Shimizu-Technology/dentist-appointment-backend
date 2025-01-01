# app/controllers/api/v1/appointments_controller.rb
module Api
  module V1
    class AppointmentsController < BaseController
      # GET /api/v1/appointments
      def index
        if current_user.admin?
          @appointments = Appointment.includes(:dentist, :appointment_type).all
        else
          @appointments = Appointment.includes(:dentist, :appointment_type)
                                     .where(user_id: current_user.id)
        end

        render json: @appointments.map { |appt| appointment_to_camel(appt) }, status: :ok
      end

      # POST /api/v1/appointments
      def create
        appointment = Appointment.new(appointment_params.merge(user_id: current_user.id))

        # Conflict check
        if Appointment.exists?(
          dentist_id: appointment.dentist_id,
          appointment_time: appointment.appointment_time,
          status: %w[scheduled]
        )
          render json: { error: "This time slot is not available." }, status: :unprocessable_entity
          return
        end

        if appointment.save
          render json: appointment_to_camel(appointment), status: :created
        else
          render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/appointments/:id
      def show
        appointment = Appointment.includes(:dentist, :appointment_type).find(params[:id])
        unless current_user.admin? || appointment.user_id == current_user.id
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        render json: appointment_to_camel(appointment), status: :ok
      end

      # PATCH/PUT /api/v1/appointments/:id
      def update
        appointment = Appointment.find(params[:id])
        unless current_user.admin? || appointment.user_id == current_user.id
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        # Check conflict only if changing dentist/time
        if appointment_params[:dentist_id].present? && appointment_params[:appointment_time].present?
          if Appointment.exists?(
            dentist_id: appointment_params[:dentist_id],
            appointment_time: appointment_params[:appointment_time],
            status: %w[scheduled]
          )
            return render json: { error: "This time slot is not available." }, status: :unprocessable_entity
          end
        end

        if appointment.update(appointment_params)
          render json: appointment_to_camel(appointment), status: :ok
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
        params.require(:appointment).permit(
          :appointment_time,
          :appointment_type_id,
          :dentist_id,
          :status,
          :dependent_id,
          :notes
        )
      end

      def appointment_to_camel(appt)
        {
          id: appt.id,
          userId: appt.user_id,
          userName: appt.user ? "#{appt.user.first_name} #{appt.user.last_name}" : nil,
          userEmail: appt.user ? appt.user.email : nil,
          dependentId: appt.dependent_id,
          dentistId: appt.dentist_id,
          appointmentTypeId: appt.appointment_type_id,
          appointmentTime: appt.appointment_time&.iso8601,
          status: appt.status,
          createdAt: appt.created_at.iso8601,
          updatedAt: appt.updated_at.iso8601,
          notes: appt.notes,
          dentist: appt.dentist && {
            id: appt.dentist.id,
            firstName: appt.dentist.first_name,
            lastName: appt.dentist.last_name,
            specialty: appt.dentist.specialty
          },
          appointmentType: appt.appointment_type && {
            id: appt.appointment_type.id,
            name: appt.appointment_type.name,
            description: appt.appointment_type.description
          }
        }
      end
    end
  end
end
