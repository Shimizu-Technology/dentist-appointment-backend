# app/controllers/api/v1/schedules_controller.rb
module Api
  module V1
    class SchedulesController < BaseController
      before_action :require_admin!

      # GET /api/v1/schedules
      # Return all scheduling info: clinic hours, closed days, dentist availabilities
      def index
        setting = ClinicSetting.singleton
        closed_days = ClosedDay.order(:date)
        dentist_availabilities = DentistAvailability.order(:dentist_id, :day_of_week)

        render json: {
          clinicOpenTime:  setting.open_time,   # e.g. "09:00"
          clinicCloseTime: setting.close_time,  # e.g. "17:00"

          closedDays: closed_days.map { |cd|
            {
              id:     cd.id,
              date:   cd.date.to_s,   # "YYYY-MM-DD"
              reason: cd.reason
            }
          },

          dentistAvailabilities: dentist_availabilities.map { |da|
            {
              id:        da.id,
              dentistId: da.dentist_id,
              dayOfWeek: da.day_of_week, # 0=Sun, 1=Mon, ...
              startTime: da.start_time,
              endTime:   da.end_time
            }
          }
        }, status: :ok
      end

      # PATCH/PUT /api/v1/schedules
      # Let admin update the single clinic open/close times
      def update
        setting = ClinicSetting.singleton
        if setting.update(
          open_time:  params[:clinic_open_time],
          close_time: params[:clinic_close_time]
        )
          render json: {
            clinicOpenTime:  setting.open_time,
            clinicCloseTime: setting.close_time
          }, status: :ok
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def require_admin!
        render(json: { error: 'Not authorized (admin only)' }, status: :forbidden) unless current_user&.admin?
      end
    end
  end
end
