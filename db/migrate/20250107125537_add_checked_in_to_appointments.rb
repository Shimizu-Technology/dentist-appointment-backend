# db/migrate/20250108123456_add_checked_in_to_appointments.rb
class AddCheckedInToAppointments < ActiveRecord::Migration[7.2]
  def change
    add_column :appointments, :checked_in, :boolean, default: false, null: false
  end
end
