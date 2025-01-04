class CreateClinicSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :clinic_settings do |t|
      t.string :open_time,  null: false, default: "09:00"
      t.string :close_time, null: false, default: "17:00"
      t.timestamps
    end
  end
end
