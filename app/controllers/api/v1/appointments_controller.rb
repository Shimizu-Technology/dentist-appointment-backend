# File: /app/controllers/api/v1/appointments_controller.rb
module Api
  module V1
    class AppointmentsController < BaseController

      # GET /api/v1/appointments
      def index
        if current_user.admin?
          base_scope = Appointment.includes(:dentist, :appointment_type, :user)
        else
          base_scope = Appointment.includes(:dentist, :appointment_type, :user)
                                   .where(user_id: current_user.id)
        end

        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

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
        # If admin and a user_id param is present, use that user_id. Otherwise use current_user.id
        chosen_user_id = if current_user.admin? && appointment_params[:user_id].present?
                           appointment_params[:user_id]
                         else
                           current_user.id
                         end

        appointment = Appointment.new(
          user_id: chosen_user_id,
          dentist_id: appointment_params[:dentist_id],
          appointment_type_id: appointment_params[:appointment_type_id],
          appointment_time: appointment_params[:appointment_time],
          dependent_id: appointment_params[:dependent_id],
          status: appointment_params[:status],
          notes: appointment_params[:notes]
        )

        # ------------------------------------------
        #  CONFLICT CHECK REMOVED (the old snippet)
        #  We'll rely on the model-level validation
        # ------------------------------------------

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

        # Same: remove any old “exact match” conflict logic
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

      # GET /api/v1/appointments/day_appointments?dentist_id=X&date=YYYY-MM-DD
      # Returns all appointments for that dentist on that specific date
      def day_appointments
        # 1. Grab required params
        dentist_id = params[:dentist_id]
        date_str   = params[:date]

        if dentist_id.blank? || date_str.blank?
          return render json: { error: "Missing dentist_id or date" }, status: :unprocessable_entity
        end

        # 2. Parse the date
        date_obj = begin
          Date.parse(date_str)
        rescue ArgumentError
          return render json: { error: "Invalid date format" }, status: :unprocessable_entity
        end

        # 3. Query appointments for that dentist on that date
        #    (We assume you have appointment_time in the DB as a DateTime)
        start_of_day = date_obj.beginning_of_day
        end_of_day   = date_obj.end_of_day

        # If an admin calls this, they see all. Otherwise, optionally check permissions if needed.
        # For simplicity, we return all appointments for the dentist on that day.
        appts = Appointment.includes(:appointment_type)
                           .where(dentist_id: dentist_id)
                           .where(appointment_time: start_of_day..end_of_day)
                           .order(:appointment_time)

        # 4. Return minimal JSON: each item has the start time + the appointment’s duration
        #    so the front end can figure out the time block that is taken.
        #    If you store the “duration” in the appointmentType, you can pass that as well.
        results = appts.map do |appt|
          {
            id: appt.id,
            appointmentTime: appt.appointment_time.iso8601,
            duration: appt.appointment_type&.duration || 30, 
            status: appt.status
          }
        end

        render json: { appointments: results }, status: :ok
      end

      private

      def appointment_params
        params.require(:appointment).permit(
          :appointment_time,
          :appointment_type_id,
          :dentist_id,
          :status,
          :dependent_id,
          :notes,
          :user_id
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
          dentist: appt.dentist && {
            id:         appt.dentist.id,
            firstName:  appt.dentist.first_name,
            lastName:   appt.dentist.last_name,
            specialty:  appt.dentist.specialty
          },
          appointmentType: appt.appointment_type && {
            id:          appt.appointment_type.id,
            name:        appt.appointment_type.name,
            description: appt.appointment_type.description,
            duration:    appt.appointment_type.duration
          }
        }
      end
    end
  end
end
