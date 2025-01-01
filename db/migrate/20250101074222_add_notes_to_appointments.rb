class AddNotesToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :notes, :text
  end
end
