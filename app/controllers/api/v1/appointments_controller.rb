# app/controllers/api/v1/appointments_controller.rb
module Api
  module V1
    class AppointmentsController < BaseController
      # GET /api/v1/appointments
      def index
        # 1) Different base scope for admin vs non-admin
        if current_user.admin?
          base_scope = Appointment.includes(:dentist, :appointment_type, :user)
        else
          base_scope = Appointment.includes(:dentist, :appointment_type, :user)
                                   .where(user_id: current_user.id)
        end

        # 2) Parse pagination params
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        # 3) Apply Kaminari pagination
        @appointments = base_scope.order(id: :desc).page(page).per(per_page)

        render json: {
          appointments: @appointments.map { |appt| appointment_to_camel(appt) },
          meta: {
            currentPage:   @appointments.current_page,
            totalPages:    @appointments.total_pages,
            totalCount:    @appointments.total_count,
            perPage:       per_page
          }
        }, status: :ok
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
          id:                 appt.id,
          userId:             appt.user_id,
          userName:           appt.user ? "#{appt.user.first_name} #{appt.user.last_name}" : nil,
          userEmail:          appt.user ? appt.user.email : nil,
          dependentId:        appt.dependent_id,
          dentistId:          appt.dentist_id,
          appointmentTypeId:  appt.appointment_type_id,
          appointmentTime:    appt.appointment_time&.iso8601,
          status:             appt.status,
          createdAt:          appt.created_at.iso8601,
          updatedAt:          appt.updated_at.iso8601,
          notes:              appt.notes,

          user: appt.user && {
            id:         appt.user.id,
            firstName:  appt.user.first_name,
            lastName:   appt.user.last_name,
            email:      appt.user.email,
            phone:      appt.user.phone
          },

          dentist: appt.dentist && {
            id:         appt.dentist.id,
            firstName:  appt.dentist.first_name,
            lastName:   appt.dentist.last_name,
            specialty:  appt.dentist.specialty
          },
          appointmentType: appt.appointment_type && {
            id:          appt.appointment_type.id,
            name:        appt.appointment_type.name,
            description: appt.appointment_type.description
          }
        }
      end
    end
  end
end
