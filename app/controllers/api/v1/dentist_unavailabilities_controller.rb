# File: app/controllers/api/v1/dentist_unavailabilities_controller.rb
module Api
  module V1
    class DentistUnavailabilitiesController < BaseController
      before_action :require_admin!

      def create
        block = DentistUnavailability.new(dentist_unavailability_params)
        if block.save
          render json: to_camel(block), status: :created
        else
          render json: { errors: block.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        block = DentistUnavailability.find(params[:id])
        if block.update(dentist_unavailability_params)
          render json: to_camel(block), status: :ok
        else
          render json: { errors: block.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        block = DentistUnavailability.find(params[:id])
        block.destroy
        render json: { message: 'Dentist unavailability removed.' }, status: :ok
      end

      private

      def dentist_unavailability_params
        params.require(:dentist_unavailability).permit(:dentist_id, :date, :start_time, :end_time, :reason)
      end

      def to_camel(du)
        {
          id: du.id,
          dentistId: du.dentist_id,
          date: du.date.to_s,
          startTime: du.start_time,
          endTime:   du.end_time,
          reason:    du.reason
        }
      end

      def require_admin!
        render json: { error: 'Not authorized' }, status: :forbidden unless current_user&.admin?
      end
    end
  end
end
