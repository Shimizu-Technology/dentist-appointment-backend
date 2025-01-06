# File: app/controllers/api/v1/appointments_controller.rb

module Api
  module V1
    class AppointmentsController < BaseController

      # GET /api/v1/appointments
      def index
        if current_user.admin?
          # Include :dependent (along with :user, :dentist, :appointment_type)
          base_scope = Appointment.includes(:dentist, :appointment_type, :user, :dependent)
        else
          # Regular user sees only their appointments
          base_scope = Appointment.includes(:dentist, :appointment_type, :user, :dependent)
                                   .where(user_id: current_user.id)
        end

        # Optional: Filter by dentist_id
        if params[:dentist_id].present?
          base_scope = base_scope.where(dentist_id: params[:dentist_id])
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
        # If admin and user_id is passed, create for that user. Otherwise, for current_user.
        chosen_user_id = if current_user.admin? && appointment_params[:user_id].present?
                           appointment_params[:user_id]
                         else
                           current_user.id
                         end

        appointment = Appointment.new(
          user_id:             chosen_user_id,
          dentist_id:          appointment_params[:dentist_id],
          appointment_type_id: appointment_params[:appointment_type_id],
          appointment_time:    appointment_params[:appointment_time],
          dependent_id:        appointment_params[:dependent_id], # could be nil if "self"
          status:              appointment_params[:status],
          notes:               appointment_params[:notes]
        )

        if appointment.save
          render json: appointment_to_camel(appointment), status: :created
        else
          render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/appointments/:id
      def show
        appointment = Appointment.includes(:dentist, :appointment_type, :user, :dependent)
                                 .find(params[:id])

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

      # GET /api/v1/appointments/day_appointments?dentist_id=X&date=YYYY-MM-DD&ignore_id=Y
      def day_appointments
        dentist_id = params[:dentist_id]
        date_str   = params[:date]
        ignore_id  = params[:ignore_id].presence

        # Check if day is globally closed
        if ClosedDay.exists?(date: date_str)
          return render json: {
            appointments: [],
            closedDay: true,
            message: "This day (#{date_str}) is globally closed."
          }, status: :ok
        end

        if dentist_id.blank? || date_str.blank?
          return render json: { error: "Missing dentist_id or date" }, status: :unprocessable_entity
        end

        date_obj = Date.parse(date_str) rescue nil
        unless date_obj
          return render json: { error: "Invalid date format" }, status: :unprocessable_entity
        end

        start_of_day = date_obj.beginning_of_day
        end_of_day   = date_obj.end_of_day

        appts = Appointment.includes(:appointment_type)
                           .where(dentist_id: dentist_id)
                           .where(appointment_time: start_of_day..end_of_day)
                           .order(:appointment_time)

        # Exclude the appointment we’re editing, if provided
        appts = appts.where.not(id: ignore_id) if ignore_id

        results = appts.map do |appt|
          {
            id:              appt.id,
            appointmentTime: appt.appointment_time.iso8601,
            duration:        appt.appointment_type&.duration || 30,
            status:          appt.status
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
          id:                appt.id,
          userId:            appt.user_id,
          userName:          appt.user ? "#{appt.user.first_name} #{appt.user.last_name}" : nil,
          userEmail:         appt.user&.email,
          dependentId:       appt.dependent_id,
          dentistId:         appt.dentist_id,
          appointmentTypeId: appt.appointment_type_id,
          appointmentTime:   appt.appointment_time&.iso8601,
          status:            appt.status,
          createdAt:         appt.created_at.iso8601,
          updatedAt:         appt.updated_at.iso8601,
          notes:             appt.notes,

          user: appt.user && {
            id:        appt.user.id,
            email:     appt.user.email,
            firstName: appt.user.first_name,
            lastName:  appt.user.last_name,
            phone:     appt.user.phone,
            role:      appt.user.role
          },

          dependent: appt.dependent && {
            id:          appt.dependent.id,
            firstName:   appt.dependent.first_name,
            lastName:    appt.dependent.last_name,
            dateOfBirth: appt.dependent.date_of_birth&.strftime('%Y-%m-%d')
          },

          dentist: appt.dentist && {
            id:        appt.dentist.id,
            firstName: appt.dentist.first_name,
            lastName:  appt.dentist.last_name,
            specialty: appt.dentist.specialty
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
