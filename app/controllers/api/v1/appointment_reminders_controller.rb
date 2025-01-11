# app/controllers/api/v1/appointment_reminders_controller.rb

module Api
  module V1
    class AppointmentRemindersController < BaseController
      before_action :require_admin!

      # GET /api/v1/appointment_reminders
      #
      # Optional query params:
      #   ?q=someSearch
      #   ?status=queued|sent|failed
      #   ?for_date=YYYY-MM-DD
      #   ?page=2
      #   ?per_page=20
      def index
        base_scope = AppointmentReminder
          .includes(appointment: :user)
          .references(:users)
          .order(created_at: :desc)

        # 1) Optional text search on first/last name, full name, or email.
        if params[:q].present?
          q = params[:q].strip.downcase

          # For PostgreSQL, you can do: first_name || ' ' || last_name
          # For MySQL, you'd do CONCAT(users.first_name, ' ', users.last_name).
          #
          # Example for PostgreSQL:
          base_scope = base_scope.where(
            <<~SQL.squish, search: "%#{q}%"
              LOWER(users.first_name) LIKE :search
              OR LOWER(users.last_name) LIKE :search
              OR LOWER(users.email) LIKE :search
              OR LOWER(users.first_name || ' ' || users.last_name) LIKE :search
            SQL
          )
        end

        # 2) Filter by status
        if params[:status].present?
          base_scope = base_scope.where(status: params[:status])
        end

        # 3) Filter by date => interpret as “scheduled_for date” (send_at)
        if params[:for_date].present?
          begin
            date_obj = Date.parse(params[:for_date])
            base_scope = base_scope.where(send_at: date_obj.beginning_of_day..date_obj.end_of_day)
          rescue ArgumentError
            # ignore invalid date
          end
        end

        # 4) Paginate
        page     = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 10).to_i
        reminders = base_scope.page(page).per(per_page)

        render json: {
          reminders: reminders.map { |r| reminder_to_camel(r) },
          meta: {
            currentPage: reminders.current_page,
            totalPages:  reminders.total_pages,
            totalCount:  reminders.total_count,
            perPage:     per_page
          }
        }, status: :ok
      end

      # PATCH/PUT /api/v1/appointment_reminders/:id
      def update
        reminder = AppointmentReminder.find(params[:id])
        updates = params.require(:appointment_reminder).permit(:phone, :status, :message, :scheduledFor)

        if updates[:scheduledFor].present?
          updates[:send_at] = updates.delete(:scheduledFor)
        end

        if reminder.update(updates)
          render json: reminder_to_camel(reminder), status: :ok
        else
          render json: { errors: reminder.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def require_admin!
        unless current_user&.admin?
          render json: { error: 'Not authorized (admin only)' }, status: :forbidden
        end
      end

      def reminder_to_camel(r)
        {
          id:            r.id,
          appointmentId: r.appointment_id,
          status:        r.status,
          phone:         r.phone,
          message:       r.message,
          scheduledFor:  r.send_at&.iso8601,
          sent:          r.sent,
          sentAt:        r.sent_at&.iso8601,
          createdAt:     r.created_at.iso8601,
          updatedAt:     r.updated_at.iso8601,

          # Appointment info
          appointment: {
            id:       r.appointment.id,
            shortRef: "##{r.appointment.id}",
            userId:   r.appointment.user_id
          },

          # Include user’s first/last/email
          user: r.appointment.user && {
            id:        r.appointment.user.id,
            firstName: r.appointment.user.first_name,
            lastName:  r.appointment.user.last_name,
            email:     r.appointment.user.email
          }
        }
      end
    end
  end
end
