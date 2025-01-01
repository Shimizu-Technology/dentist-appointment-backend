class AddDurationToAppointmentTypes < ActiveRecord::Migration[7.2]
  def change
    add_column :appointment_types, :duration, :integer
  end
end
