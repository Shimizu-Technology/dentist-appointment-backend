# File: app/controllers/api/v1/clinic_day_settings_controller.rb

module Api
  module V1
    class ClinicDaySettingsController < BaseController
      before_action :require_admin!

      # GET /api/v1/clinic_day_settings
      def index
        @day_settings = ClinicDaySetting.order(:day_of_week)

        # Return JSON in the structure your frontend expects
        render json: @day_settings.map { |ds|
          {
            id:         ds.id,
            dayOfWeek:  ds.day_of_week,
            isOpen:     ds.is_open,
            openTime:   ds.open_time,
            closeTime:  ds.close_time
          }
        }, status: :ok
      end

      # PATCH /api/v1/clinic_day_settings/:id
      def update
        # Find the record by ID
        ds = ClinicDaySetting.find(params[:id])
        # Expect front-end sends { clinic_day_setting: { isOpen: ..., openTime: ..., closeTime: ... } }
        updates = params.require(:clinic_day_setting).permit(:isOpen, :openTime, :closeTime)

        # Convert them to the names in your DB: is_open, open_time, close_time
        success = ds.update(
          is_open:    updates[:isOpen],
          open_time:  updates[:openTime],
          close_time: updates[:closeTime]
        )

        if success
          render json: { message: "Updated day #{ds.day_of_week}" }, status: :ok
        else
          render json: { errors: ds.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def require_admin!
        render json: { error: "Not authorized" }, status: :forbidden unless current_user&.admin?
      end
    end
  end
end
