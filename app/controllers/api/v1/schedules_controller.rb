# app/controllers/api/v1/schedules_controller.rb
module Api
  module V1
    class SchedulesController < BaseController
      before_action :require_admin!

      # GET /api/v1/schedule
      def show
        setting = ClinicSetting.singleton
        closed_days = ClosedDay.order(:date)
        dentist_availabilities = DentistAvailability.order(:dentist_id, :day_of_week)

        # Convert open_days (e.g. "1,2,3,4,5") to an array of integers [1,2,3,4,5]
        open_days_array = setting.open_days.split(",").map(&:to_i)

        render json: {
          clinicOpenTime:  setting.open_time,
          clinicCloseTime: setting.close_time,
          openDays:        open_days_array,  # e.g. [1,2,3,4,5]

          closedDays: closed_days.map { |cd|
            {
              id:     cd.id,
              date:   cd.date.to_s,
              reason: cd.reason
            }
          },

          dentistAvailabilities: dentist_availabilities.map { |da|
            {
              id:        da.id,
              dentistId: da.dentist_id,
              dayOfWeek: da.day_of_week,
              startTime: da.start_time,
              endTime:   da.end_time
            }
          }
        }, status: :ok
      end

      # PATCH /api/v1/schedule
      def update
        setting = ClinicSetting.singleton

        # Expecting params[:open_days] to be an array of day indexes (e.g. [1,2,3,4,5])
        open_days_str = if params[:open_days].present?
          params[:open_days].join(",") # turn [1,2,3] into "1,2,3"
        else
          # if nothing provided, fallback to empty string or default
          ""
        end

        if setting.update(
          open_time:  params[:clinic_open_time],
          close_time: params[:clinic_close_time],
          open_days:  open_days_str
        )
          render json: {
            clinicOpenTime:  setting.open_time,
            clinicCloseTime: setting.close_time,
            openDays:        setting.open_days.split(",").map(&:to_i)
          }, status: :ok
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def require_admin!
        render(
          json:   { error: 'Not authorized (admin only)' },
          status: :forbidden
        ) unless current_user&.admin?
      end
    end
  end
end
