class CreateAppointmentTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :appointment_types do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
