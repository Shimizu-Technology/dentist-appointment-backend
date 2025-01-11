# app/controllers/api/v1/schedules_controller.rb
module Api
  module V1
    class SchedulesController < BaseController
      before_action :require_admin!, only: [:update]

      # GET /api/v1/schedule
      def show
        # 1) Grab all day-of-week settings
        day_settings = ClinicDaySetting.order(:day_of_week)

        # 2) Grab closed days
        closed_days = ClosedDay.order(:date)

        # 3) Grab dentist unavailabilities
        dentist_unavailabilities = DentistUnavailability.order(:dentist_id, :date, :start_time)

        render json: {
          # Return the full day-of-week settings
          clinicDaySettings: day_settings.map { |ds| day_setting_to_camel(ds) },

          # The "closedDays" array
          closedDays: closed_days.map { |cd| closed_day_to_camel(cd) },

          # Dentist unavailabilities
          dentistUnavailabilities: dentist_unavailabilities.map { |du| unavail_to_camel(du) }
        }, status: :ok
      end

      # PATCH /api/v1/schedule
      # (optional if you have a bulk update endpoint)
      def update
        unless params[:clinic_day_settings].is_a?(Array)
          return render json: { error: "Expected clinic_day_settings to be an array" }, status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          params[:clinic_day_settings].each do |day_hash|
            ds = ClinicDaySetting.find_or_initialize_by(day_of_week: day_hash[:day_of_week])
            ds.is_open    = day_hash[:is_open]
            ds.open_time  = day_hash[:open_time]
            ds.close_time = day_hash[:close_time]
            ds.save!
          end
        end

        # Return the updated list
        all_settings = ClinicDaySetting.order(:day_of_week)
        render json: {
          clinicDaySettings: all_settings.map { |ds| day_setting_to_camel(ds) }
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end

      private

      def require_admin!
        render json: { error: 'Not authorized (admin only)' }, status: :forbidden unless current_user&.admin?
      end

      # Helper methods to keep JSON consistent
      def day_setting_to_camel(ds)
        {
          id:         ds.id,
          dayOfWeek:  ds.day_of_week,
          isOpen:     ds.is_open,
          openTime:   ds.open_time,
          closeTime:  ds.close_time
        }
      end

      def closed_day_to_camel(cd)
        {
          id: cd.id,
          date: cd.date.to_s,
          reason: cd.reason
        }
      end

      def unavail_to_camel(du)
        {
          id:        du.id,
          dentistId: du.dentist_id,
          date:      du.date.to_s,
          startTime: du.start_time,
          endTime:   du.end_time,
          reason:    du.reason
        }
      end
    end
  end
end
