# frozen_string_literal: true

module Api
  module V1
    class DentistsController < BaseController
      skip_before_action :authenticate_user!, only: [:index, :show]

      # GET /api/v1/dentists
      def index
        dentists = Dentist.all
        render json: dentists, status: :ok
      end

      # GET /api/v1/dentists/:id
      def show
        dentist = Dentist.find(params[:id])
        render json: dentist, status: :ok
      end

      # POST /api/v1/dentists
      # Typically only admins can create new dentists
      def create
        return not_admin unless current_user.admin?

        dentist = Dentist.new(dentist_params)
        if dentist.save
          render json: dentist, status: :created
        else
          render json: { errors: dentist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/dentists/:id
      # Typically only admins can edit dentists
      def update
        return not_admin unless current_user.admin?

        dentist = Dentist.find(params[:id])
        if dentist.update(dentist_params)
          render json: dentist, status: :ok
        else
          render json: { errors: dentist.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/dentists/:id
      # Typically only admins can remove dentists
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
    end
  end
end
