# File: app/controllers/api/v1/dentist_availabilities_controller.rb

module Api
  module V1
    class DentistAvailabilitiesController < BaseController
      before_action :require_admin!

      # POST /api/v1/dentist_availabilities
      def create
        # Example: parameters come in as:
        # {
        #   dentist_availability: {
        #     dentist_id: 1,
        #     day_of_week: 1,
        #     start_time: '09:00',
        #     end_time: '17:00'
        #   }
        # }
        avail = DentistAvailability.new(dentist_availability_params)

        if avail.save
          render json: to_json(avail), status: :created
        else
          render json: { errors: avail.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/dentist_availabilities/:id
      def update
        avail = DentistAvailability.find(params[:id])

        if avail.update(dentist_availability_params)
          render json: to_json(avail), status: :ok
        else
          render json: { errors: avail.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/dentist_availabilities/:id
      def destroy
        avail = DentistAvailability.find(params[:id])
        avail.destroy
        render json: { message: 'Dentist availability removed' }, status: :ok
      end

      private

      def require_admin!
        return if current_user&.admin?

        render json: { error: 'Not authorized (admin only)' }, status: :forbidden
      end

      def dentist_availability_params
        # Strong parameters
        params.require(:dentist_availability).permit(
          :dentist_id, :day_of_week, :start_time, :end_time
        )
      end

      def to_json(avail)
        {
          id: avail.id,
          dentistId: avail.dentist_id,
          dayOfWeek: avail.day_of_week,
          startTime: avail.start_time,
          endTime:   avail.end_time
        }
      end
    end
  end
end
