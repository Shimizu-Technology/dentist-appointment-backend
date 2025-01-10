# db/migrate/20231005000000_create_appointment_reminders.rb
class CreateAppointmentReminders < ActiveRecord::Migration[7.0]
  def change
    create_table :appointment_reminders do |t|
      t.references :appointment, null: false, foreign_key: true
      t.datetime :send_at,      null: false
      t.boolean :sent,          default: false
      t.datetime :sent_at

      t.timestamps
    end
  end
end
