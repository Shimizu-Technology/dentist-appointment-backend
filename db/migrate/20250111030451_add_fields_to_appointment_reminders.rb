# db/migrate/20250111120000_add_fields_to_appointment_reminders.rb
class AddFieldsToAppointmentReminders < ActiveRecord::Migration[7.2]
  def change
    add_column :appointment_reminders, :message, :text
    add_column :appointment_reminders, :phone, :string
    add_column :appointment_reminders, :status, :string, default: "queued"
    # if you want to rename `send_at` → `scheduled_for`, or keep it as is. 
    # For now, we'll keep `send_at` as is.
  end
end
