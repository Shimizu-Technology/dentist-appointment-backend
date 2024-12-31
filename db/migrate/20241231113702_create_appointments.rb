class CreateAppointments < ActiveRecord::Migration[7.2]
  def change
    create_table :appointments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :dependent, null: false, foreign_key: true
      t.references :dentist, null: false, foreign_key: true
      t.references :appointment_type, null: false, foreign_key: true
      t.datetime :appointment_time
      t.string :status

      t.timestamps
    end
  end
end
