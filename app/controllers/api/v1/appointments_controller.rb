# File: app/controllers/api/v1/appointments_controller.rb

module Api
  module V1
    class AppointmentsController < BaseController
      before_action :authenticate_user!

      # GET /api/v1/appointments
      def index
        Rails.logger.info "[AppointmentsController#index] current_user.id=#{current_user.id}, role=#{current_user.role}"
        puts "[AppointmentsController#index] current_user.id=#{current_user.id}, role=#{current_user.role}"

        if current_user.admin?
          if params[:user_id] == 'me'
            # Even if they're admin, if "me" was requested, also include child-users
            my_child_ids = current_user.child_users.pluck(:id)
            Rails.logger.info "[AppointmentsController#index] Admin requested 'me'; my_child_ids=#{my_child_ids}"
            puts "[AppointmentsController#index] Admin requested 'me'; my_child_ids=#{my_child_ids}"
            base_scope = Appointment
              .includes(:dentist, :appointment_type, :user)
              .where(user_id: [current_user.id] + my_child_ids)
          elsif params[:user_id].present?
            # Admin requesting appointments for a specific user
            Rails.logger.info "[AppointmentsController#index] Admin requested user_id=#{params[:user_id]}"
            puts "[AppointmentsController#index] Admin requested user_id=#{params[:user_id]}"
            base_scope = Appointment
              .includes(:dentist, :appointment_type, :user)
              .where(user_id: params[:user_id])
          else
            # Admin sees everything by default
            Rails.logger.info "[AppointmentsController#index] Admin sees all"
            puts "[AppointmentsController#index] Admin sees all"
            base_scope = Appointment
              .includes(:dentist, :appointment_type, :user)
          end
        else
          # Non-admin => see own appointments + child users' appointments
          my_child_ids = current_user.child_users.pluck(:id)
          Rails.logger.info "[AppointmentsController#index] Non-admin => user=#{current_user.id}, children=#{my_child_ids}"
          puts "[AppointmentsController#index] Non-admin => user=#{current_user.id}, children=#{my_child_ids}"
          base_scope = Appointment
            .includes(:dentist, :appointment_type, :user)
            .where(user_id: [current_user.id] + my_child_ids)
        end

        # >>> ADD: numeric dentist filter if `dentist_id` is present <<<
        if params[:dentist_id].present?
          base_scope = base_scope.where(dentist_id: params[:dentist_id])
        end

        # Optional filters
        if params[:q].present?
          search = params[:q].strip.downcase
          base_scope = base_scope.joins(:user).where(
            %q{
              LOWER(users.first_name) LIKE :s
              OR LOWER(users.last_name) LIKE :s
              OR LOWER(users.first_name || ' ' || users.last_name) LIKE :s
              OR LOWER(users.email) LIKE :s
              OR CAST(users.id AS TEXT) = :exact_s
            },
            s: "%#{search}%",
            exact_s: search
          )
        end

        if params[:dentist_name].present?
          name_search = params[:dentist_name].strip.downcase
          base_scope = base_scope.joins(:dentist).where(
            "LOWER(dentists.first_name || ' ' || dentists.last_name) LIKE ?",
            "%#{name_search}%"
          )
        end

        if params[:date].present?
          begin
            date_obj = Date.parse(params[:date])
            base_scope = base_scope.where(
              appointment_time: date_obj.beginning_of_day..date_obj.end_of_day
            )
          rescue ArgumentError
            # ignore invalid date
          end
        end

        if params[:status].present?
          if params[:status] == 'past'
            base_scope = base_scope.where("appointment_time < ?", Time.now)
          else
            base_scope = base_scope.where(status: params[:status])
          end
        end

        # Pagination
        page     = (params[:page].presence || 1).to_i
        per_page = (params[:per_page].presence || 10).to_i

        @appointments = base_scope
          .order(appointment_time: :asc)
          .page(page).per(per_page)

        render json: {
          appointments: @appointments.map { |appt| appointment_to_camel(appt) },
          meta: {
            currentPage: @appointments.current_page,
            totalPages:  @appointments.total_pages,
            totalCount:  @appointments.total_count,
            perPage:     per_page
          }
        }, status: :ok
      end

      # POST /api/v1/appointments
      def create
        Rails.logger.info "[AppointmentsController#create] current_user=#{current_user.id}, params=#{params.inspect}"
        puts "[AppointmentsController#create] current_user=#{current_user.id}, params=#{params.inspect}"

        chosen_user_id = determine_appointment_user_id
        Rails.logger.info "[AppointmentsController#create] chosen_user_id=#{chosen_user_id}"
        puts "[AppointmentsController#create] chosen_user_id=#{chosen_user_id}"

        appointment = Appointment.new(
          user_id:             chosen_user_id,
          dentist_id:          create_params[:dentist_id],
          appointment_type_id: create_params[:appointment_type_id],
          appointment_time:    create_params[:appointment_time],
          status:              create_params[:status],
          notes:               create_params[:notes],
          checked_in:          create_params[:checked_in]
        )

        if appointment.save
          Rails.logger.info "[AppointmentsController#create] Successfully created appointment.id=#{appointment.id}"
          puts "[AppointmentsController#create] Successfully created appointment.id=#{appointment.id}"
          AppointmentMailer.booking_confirmation(appointment).deliver_later
          render json: appointment_to_camel(appointment), status: :created
        else
          Rails.logger.warn "[AppointmentsController#create] Failed to create appointment: #{appointment.errors.full_messages}"
          puts "[AppointmentsController#create] Failed to create appointment: #{appointment.errors.full_messages}"
          render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/appointments/:id
      def show
        Rails.logger.info "[AppointmentsController#show] current_user=#{current_user.id}, requested.id=#{params[:id]}"
        puts "[AppointmentsController#show] current_user=#{current_user.id}, requested.id=#{params[:id]}"

        appointment = Appointment
          .includes(:dentist, :appointment_type, :user)
          .find_by(id: params[:id])
        unless appointment
          Rails.logger.warn "[AppointmentsController#show] Appointment #{params[:id]} not found!"
          puts "[AppointmentsController#show] Appointment #{params[:id]} not found!"
          return render_not_found
        end

        Rails.logger.info "[AppointmentsController#show] Appointment found: user_id=#{appointment.user_id}"
        puts "[AppointmentsController#show] Appointment found: user_id=#{appointment.user_id}"
        unless current_user.admin? || appointment_belongs_to_me?(appointment)
          Rails.logger.warn "[AppointmentsController#show] Not authorized. current_user=#{current_user.id}, child_users=#{current_user.child_users.pluck(:id)}, appointment.user_id=#{appointment.user_id}"
          puts "[AppointmentsController#show] Not authorized. current_user=#{current_user.id}, child_users=#{current_user.child_users.pluck(:id)}, appointment.user_id=#{appointment.user_id}"
          return render json: { error: 'Not authorized' }, status: :forbidden
        end

        render json: appointment_to_camel(appointment), status: :ok
      end

      # PATCH/PUT /api/v1/appointments/:id
      def update
        Rails.logger.info "[AppointmentsController#update] current_user=#{current_user.id}, requested.id=#{params[:id]}, params=#{params.inspect}"
        puts "[AppointmentsController#update] current_user=#{current_user.id}, requested.id=#{params[:id]}, params=#{params.inspect}"

        appointment = Appointment.find_by(id: params[:id])
        unless appointment
          Rails.logger.warn "[AppointmentsController#update] Appointment #{params[:id]} not found!"
          puts "[AppointmentsController#update] Appointment #{params[:id]} not found!"
          return render_not_found
        end

        Rails.logger.info "[AppointmentsController#update] Found appointment: user_id=#{appointment.user_id}"
        puts "[AppointmentsController#update] Found appointment: user_id=#{appointment.user_id}"
        unless current_user.admin? || appointment_belongs_to_me?(appointment)
          Rails.logger.warn "[AppointmentsController#update] Not authorized. current_user=#{current_user.id}, child_users=#{current_user.child_users.pluck(:id)}, appointment.user_id=#{appointment.user_id}"
          puts "[AppointmentsController#update] Not authorized. current_user=#{current_user.id}, child_users=#{current_user.child_users.pluck(:id)}, appointment.user_id=#{appointment.user_id}"
          return render json: { error: 'Not authorized' }, status: :forbidden
        end

        old_time = appointment.appointment_time
        old_dent = appointment.dentist_id
        old_type = appointment.appointment_type_id

        if appointment.update(update_params)
          Rails.logger.info "[AppointmentsController#update] Appointment #{appointment.id} updated successfully."
          puts "[AppointmentsController#update] Appointment #{appointment.id} updated successfully."

          # If time/dentist/type changed => send reschedule email
          if (appointment.appointment_time != old_time) ||
             (appointment.dentist_id != old_dent)      ||
             (appointment.appointment_type_id != old_type)
            Rails.logger.info "[AppointmentsController#update] Reschedule triggered for appointment.id=#{appointment.id}"
            puts "[AppointmentsController#update] Reschedule triggered for appointment.id=#{appointment.id}"
            AppointmentMailer.reschedule_notification(appointment).deliver_later
          end
          render json: appointment_to_camel(appointment), status: :ok
        else
          Rails.logger.warn "[AppointmentsController#update] Failed to update appointment: #{appointment.errors.full_messages}"
          puts "[AppointmentsController#update] Failed to update appointment: #{appointment.errors.full_messages}"
          render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/appointments/:id
      def destroy
        Rails.logger.info "[AppointmentsController#destroy] current_user=#{current_user.id}, requested.id=#{params[:id]}"
        puts "[AppointmentsController#destroy] current_user=#{current_user.id}, requested.id=#{params[:id]}"

        appointment = Appointment.find_by(id: params[:id])
        unless appointment
          Rails.logger.warn "[AppointmentsController#destroy] Appointment #{params[:id]} not found!"
          puts "[AppointmentsController#destroy] Appointment #{params[:id]} not found!"
          return render_not_found
        end

        Rails.logger.info "[AppointmentsController#destroy] Found appointment: user_id=#{appointment.user_id}"
        puts "[AppointmentsController#destroy] Found appointment: user_id=#{appointment.user_id}"
        unless current_user.admin? || appointment_belongs_to_me?(appointment)
          Rails.logger.warn "[AppointmentsController#destroy] Not authorized. current_user=#{current_user.id}, child_users=#{current_user.child_users.pluck(:id)}, appointment.user_id=#{appointment.user_id}"
          puts "[AppointmentsController#destroy] Not authorized. current_user=#{current_user.id}, child_users=#{current_user.child_users.pluck(:id)}, appointment.user_id=#{appointment.user_id}"
          return render json: { error: 'Not authorized' }, status: :forbidden
        end

        if appointment.destroy
          Rails.logger.info "[AppointmentsController#destroy] Appointment #{appointment.id} destroyed. Sending cancellation mail..."
          puts "[AppointmentsController#destroy] Appointment #{appointment.id} destroyed. Sending cancellation mail..."
          AppointmentMailer.cancellation_notification(appointment).deliver_now
          render json: { message: 'Appointment canceled.' }, status: :ok
        else
          Rails.logger.warn "[AppointmentsController#destroy] Failed to destroy appointment: #{appointment.errors.full_messages}"
          puts "[AppointmentsController#destroy] Failed to destroy appointment: #{appointment.errors.full_messages}"
          render json: { errors: appointment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/appointments/:id/check_in
      def check_in
        return not_admin unless current_user.admin?

        appointment = Appointment.find_by(id: params[:id])
        return render_not_found unless appointment

        new_val = !appointment.checked_in
        appointment.update!(checked_in: new_val)
        render json: appointment_to_camel(appointment), status: :ok
      end

      # GET /api/v1/appointments/day_appointments
      def day_appointments
        dentist_id = params[:dentist_id]
        date_str   = params[:date]
        ignore_id  = params[:ignore_id]

        if ClosedDay.exists?(date: date_str)
          return render json: {
            appointments: [],
            closedDay: true,
            message: "This day (#{date_str}) is globally closed."
          }, status: :ok
        end

        if dentist_id.blank? || date_str.blank?
          return render json: { error: 'Missing dentist_id or date' }, status: :unprocessable_entity
        end

        date_obj = Date.parse(date_str) rescue nil
        return render json: { error: 'Invalid date format' }, status: :unprocessable_entity unless date_obj

        start_of_day = date_obj.beginning_of_day
        end_of_day   = date_obj.end_of_day

        appts = Appointment
          .includes(:appointment_type)
          .where(dentist_id: dentist_id)
          .where(appointment_time: start_of_day..end_of_day)
          .order(:appointment_time)

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

      def render_not_found
        Rails.logger.warn "[AppointmentsController] Appointment not found. Returning 404."
        puts "[AppointmentsController] Appointment not found. Returning 404."
        render json: { error: 'Appointment not found' }, status: :not_found
      end

      def not_admin
        Rails.logger.warn "[AppointmentsController] Attempted admin-only action by user=#{current_user.id}"
        puts "[AppointmentsController] Attempted admin-only action by user=#{current_user.id}"
        render json: { error: 'Not authorized (admin only)' }, status: :forbidden
      end

      #
      # Decide who the appointment should belong to (only used on create).
      #
      def determine_appointment_user_id
        if create_params[:child_user_id].present?
          # If child_user_id is provided, ensure it belongs to current_user (unless admin)
          if current_user.admin?
            create_params[:child_user_id]
          else
            child_user = current_user.child_users.find(create_params[:child_user_id])
            child_user.id
          end
        elsif create_params[:user_id].present? && current_user.admin?
          # If user_id is provided and current_user is admin, use that
          create_params[:user_id]
        else
          # Otherwise fallback to the current user
          current_user.id
        end
      end

      #
      # Permit only these attributes during creation (includes child_user_id).
      #
      def create_params
        params.require(:appointment).permit(
          :appointment_time,
          :appointment_type_id,
          :dentist_id,
          :status,
          :notes,
          :user_id,         # used by admins
          :child_user_id,   # used by normal users or admins
          :checked_in
        )
      end

      #
      # Permit a different set during update — do NOT permit child_user_id.
      #
      def update_params
        params.require(:appointment).permit(
          :appointment_time,
          :appointment_type_id,
          :dentist_id,
          :status,
          :notes,
          :user_id,         # if an admin reassigns the appt
          :checked_in
        )
      end

      def appointment_belongs_to_me?(appointment)
        is_mine = (appointment.user_id == current_user.id) ||
                  current_user.child_users.exists?(id: appointment.user_id)

        Rails.logger.info "[AppointmentsController] appointment_belongs_to_me? => "\
                          "current_user=#{current_user.id}, appointment.user_id=#{appointment.user_id}, "\
                          "child_user_ids=#{current_user.child_users.pluck(:id)}, is_mine=#{is_mine}"
        puts "[AppointmentsController] appointment_belongs_to_me? => "\
             "current_user=#{current_user.id}, appointment.user_id=#{appointment.user_id}, "\
             "child_user_ids=#{current_user.child_users.pluck(:id)}, is_mine=#{is_mine}"

        is_mine
      end

      def appointment_to_camel(appt)
        {
          id:                appt.id,
          userId:            appt.user_id,
          dentistId:         appt.dentist_id,
          appointmentTypeId: appt.appointment_type_id,
          appointmentTime:   appt.appointment_time&.iso8601,
          status:            appt.status,
          notes:             appt.notes,
          checkedIn:         appt.checked_in,
          createdAt:         appt.created_at.iso8601,
          updatedAt:         appt.updated_at.iso8601,
          user: appt.user && {
            id:          appt.user.id,
            email:       appt.user.email,
            firstName:   appt.user.first_name,
            lastName:    appt.user.last_name,
            phone:       appt.user.phone,
            role:        appt.user.role,
            isDependent: appt.user.is_dependent?
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
