# app/controllers/api/v1/dentists_controller.rb
module Api
  module V1
    class DentistsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show, :availabilities]

      # GET /api/v1/dentists
      def index
        # Include the specialty to avoid N+1 queries
        dentists = Dentist.includes(:specialty).all
        render json: dentists.map { |d| dentist_to_camel(d) }, status: :ok
      end

      # GET /api/v1/dentists/:id
      def show
        dentist = Dentist.includes(:specialty).find(params[:id])
        render json: dentist_to_camel(dentist), status: :ok
      end

      # GET /api/v1/dentists/:id/availabilities
      def availabilities
        dentist = Dentist.find(params[:id])
        availability = dentist.dentist_availabilities.order(:day_of_week)

        # Convert availability records to expected JSON
        render json: availability.map { |a| availability_to_camel(a) }, status: :ok
      end

      # POST /api/v1/dentists (admin only)
      def create
        return not_admin unless current_user.admin?

        # Note: param :specialty_id references the Specialty record
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
        # If your front-end sends something like:
        # {
        #   "dentist": {
        #     "first_name": "...",
        #     "last_name": "...",
        #     "specialty_id": 3,
        #     "image_url": "http://...",
        #     "qualifications": "Line1\nLine2"
        #   }
        # }
        params.require(:dentist).permit(
          :first_name, :last_name,
          :specialty_id,
          :image_url, :qualifications
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
          # If you store the specialty's name:
          specialty: d.specialty&.name,
          # or specialty object:
          # specialty: d.specialty && {
          #   id: d.specialty.id,
          #   name: d.specialty.name
          # },
          imageUrl: d.image_url,
          qualifications: d.qualifications ? d.qualifications.split("\n") : [],
          createdAt: d.created_at.iso8601,
          updatedAt: d.updated_at.iso8601
        }
      end

      def availability_to_camel(avail)
        {
          dentistId: avail.dentist_id,
          dayOfWeek: avail.day_of_week,
          startTime: avail.start_time,
          endTime: avail.end_time
        }
      end
    end
  end
end
