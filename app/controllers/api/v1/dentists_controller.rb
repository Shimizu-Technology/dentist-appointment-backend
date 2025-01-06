# app/controllers/api/v1/dentists_controller.rb

module Api
  module V1
    class DentistsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :availabilities]

      # GET /api/v1/dentists
      def index
        # Include specialty to avoid N+1 queries
        dentists = Dentist.includes(:specialty).all
        render json: dentists.map { |d| dentist_to_camel(d) }, status: :ok
      end

      # GET /api/v1/dentists/:id
      def show
        dentist = Dentist.includes(:specialty).find(params[:id])
        render json: dentist_to_camel(dentist), status: :ok
      end

      # GET /api/v1/dentists/:id/availabilities
      #
      # In your front end, you’re calling `/dentists/:id/availabilities`.
      # But your DB table is “dentist_unavailabilities.” So here, we interpret
      # them as “the dentist is UNavailable at these times/dates” and return them.
      #
      # If you truly want an “available” schedule, you’d do the inverse. For now,
      # we’ll just return `dentist_unavailabilities` in a JSON array.
      def availabilities
        dentist = Dentist.find(params[:id])
        unavailabilities = dentist.dentist_unavailabilities.order(:date, :start_time)

        # Convert them to JSON
        render json: unavailabilities.map { |u| unavailability_to_camel(u) }, status: :ok
      end

      # POST /api/v1/dentists (admin only)
      def create
        return not_admin unless current_user.admin?

        dentist = Dentist.new(dentist_params)
        if dentist.save
          render json: dentist_to_camel(dentist), status: :created
        else
          render json: { errors: dentist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/dentists/:id (admin only)
      def update
        return not_admin unless current_user.admin?

        dentist = Dentist.find(params[:id])
        if dentist.update(dentist_params)
          render json: dentist_to_camel(dentist), status: :ok
        else
          render json: { errors: dentist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/dentists/:id (admin only)
      def destroy
        return not_admin unless current_user.admin?

        dentist = Dentist.find(params[:id])
        dentist.destroy
        render json: { message: "Dentist removed" }, status: :ok
      end

      private

      def dentist_params
        params.require(:dentist).permit(
          :first_name, :last_name,
          :specialty_id,
          :image_url,
          :qualifications
        )
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end

      def dentist_to_camel(d)
        {
          id: d.id,
          firstName: d.first_name,
          lastName: d.last_name,
          specialty: d.specialty&.name,
          imageUrl: d.image_url,
          qualifications: d.qualifications ? d.qualifications.split("\n") : [],
          createdAt: d.created_at.iso8601,
          updatedAt: d.updated_at.iso8601
        }
      end

      # Convert a DentistUnavailability record to JSON in “camelCase” style
      def unavailability_to_camel(u)
        {
          id:        u.id,
          dentistId: u.dentist_id,
          date:      u.date.to_s,
          startTime: u.start_time,
          endTime:   u.end_time,
          reason:    u.reason
        }
      end      
    end
  end
end
