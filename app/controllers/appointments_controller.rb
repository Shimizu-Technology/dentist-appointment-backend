class AppointmentsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.admin?
      @appointments = Appointment.all
    else
      # Show only the user's appointments + children’s
      @appointments = Appointment.where(user_id: current_user.id)
      # Possibly also include dependent's user_id = current_user
    end
  end

  def new
    @appointment = Appointment.new
    @dentists = Dentist.all
    @appointment_types = AppointmentType.all
    @dependents = current_user.dependents
  end

  def create
    @appointment = Appointment.new(appointment_params)
    # Basic conflict check:
    if Appointment.exists?(dentist_id: @appointment.dentist_id,
                           appointment_time: @appointment.appointment_time,
                           status: ["scheduled", "pending"]) # if you have 'pending'
      flash[:alert] = "This time slot is not available."
      render :new
    else
      if @appointment.save
        flash[:notice] = "Appointment created successfully."
        redirect_to appointments_path
      else
        render :new
      end
    end
  end

  def edit
    @appointment = Appointment.find(params[:id])
    # ... plus any logic to ensure only admin or correct user can edit
  end

  def update
    @appointment = Appointment.find(params[:id])
    # same conflict check if time or dentist changes
    if @appointment.update(appointment_params)
      flash[:notice] = "Appointment updated."
      redirect_to appointments_path
    else
      render :edit
    end
  end

  def destroy
    @appointment = Appointment.find(params[:id])
    @appointment.destroy
    flash[:notice] = "Appointment canceled."
    redirect_to appointments_path
  end

  private

  def appointment_params
    params.require(:appointment).permit(:appointment_time, :appointment_type_id, 
                                       :dentist_id, :status, :dependent_id)
          .merge(user_id: current_user.id)
  end
end
