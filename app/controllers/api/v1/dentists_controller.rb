# app/controllers/api/v1/dentists_controller.rb
module Api
  module V1
    class DentistsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show]

      # GET /api/v1/dentists
      def index
        dentists = Dentist.all
        render json: dentists.map { |d| dentist_to_camel(d) }, status: :ok
      end

      # GET /api/v1/dentists/:id
      def show
        dentist = Dentist.find(params[:id])
        render json: dentist_to_camel(dentist), status: :ok
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
        params.require(:dentist).permit(:first_name, :last_name, :specialty)
      end

      def not_admin
        render json: { error: "Not authorized (admin only)" }, status: :forbidden
      end

      def dentist_to_camel(d)
        {
          id: d.id,
          firstName: d.first_name,
          lastName: d.last_name,
          specialty: d.specialty,
          # If you store more fields (like an imageUrl), you can add them
        }
      end
    end
  end
end
