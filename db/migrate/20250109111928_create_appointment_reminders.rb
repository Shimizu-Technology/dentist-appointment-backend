class CreateAppointmentReminders < ActiveRecord::Migration[7.2]
  def change
    create_table :appointment_reminders do |t|
      t.references :appointment, null: false, foreign_key: true
      t.datetime :send_at, null: false        # When exactly we plan to send it
      t.string :delivery_method, null: false  # "email", "sms", or "both"
      t.boolean :sent, default: false, null: false
      t.datetime :sent_at

      # Optionally, store some note about "1 day before" or "7 days before"
      t.string :label

      t.timestamps
    end

    # If you want to efficiently query unsent reminders
    add_index :appointment_reminders, [:sent, :send_at]
  end
end
