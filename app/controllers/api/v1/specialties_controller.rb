# app/controllers/api/v1/specialties_controller.rb
module Api
  module V1
    class SpecialtiesController < BaseController
      # Let the public see specialties if you want (e.g. for listing them).
      skip_before_action :authenticate_user!, only: [:index, :show]

      # GET /api/v1/specialties
      def index
        specialties = Specialty.all
        render json: specialties.map { |s| specialty_to_camel(s) }, status: :ok
      end

      # GET /api/v1/specialties/:id
      def show
        specialty = Specialty.find(params[:id])
        render json: specialty_to_camel(specialty), status: :ok
      end

      # POST /api/v1/specialties (admin only)
      def create
        return not_admin unless current_user.admin?

        specialty = Specialty.new(specialty_params)
        if specialty.save
          render json: specialty_to_camel(specialty), status: :created
        else
          render json: { errors: specialty.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/specialties/:id (admin only)
      def update
        return not_admin unless current_user.admin?

        specialty = Specialty.find(params[:id])
        if specialty.update(specialty_params)
          render json: specialty_to_camel(specialty), status: :ok
        else
          render json: { errors: specialty.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/specialties/:id (admin only)
      def destroy
        return not_admin unless current_user.admin?

        specialty = Specialty.find(params[:id])
        specialty.destroy
        render json: { message: "Specialty removed" }, status: :ok
      end

      private

      def specialty_params
        params.require(:specialty).permit(:name)
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end

      def specialty_to_camel(s)
        {
          id: s.id,
          name: s.name,
          createdAt: s.created_at.iso8601,
          updatedAt: s.updated_at.iso8601
        }
      end
    end
  end
end
