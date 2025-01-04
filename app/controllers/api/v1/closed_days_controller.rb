# File: app/controllers/api/v1/closed_days_controller.rb
module Api
  module V1
    class ClosedDaysController < BaseController
      before_action :require_admin!

      # GET /api/v1/closed_days
      def index
        closed_days = ClosedDay.order(:date)
        render json: closed_days.map { |cd| closed_day_to_camel(cd) }, status: :ok
      end

      # POST /api/v1/closed_days
      def create
        cd = ClosedDay.new(closed_day_params)
        if cd.save
          render json: closed_day_to_camel(cd), status: :created
        else
          render json: { errors: cd.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/closed_days/:id
      def destroy
        cd = ClosedDay.find(params[:id])
        cd.destroy
        render json: { message: 'Closed day removed' }, status: :ok
      end

      private

      def require_admin!
        # If your BaseController handles “current_user”, we just check if they’re an admin:
        render(json: { error: 'Not authorized (admin only)' }, status: :forbidden) unless current_user.admin?
      end

      def closed_day_params
        # e.g. { "closed_day": { "date": "2025-12-25", "reason": "Christmas Holiday" } }
        params.require(:closed_day).permit(:date, :reason)
      end

      def closed_day_to_camel(cd)
        {
          id: cd.id,
          date: cd.date.to_s, # "YYYY-MM-DD"
          reason: cd.reason,
          createdAt: cd.created_at.iso8601,
          updatedAt: cd.updated_at.iso8601
        }
      end
    end
  end
end
