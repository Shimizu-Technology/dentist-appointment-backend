class CreateClinicDaySettings < ActiveRecord::Migration[7.2]
  def change
    create_table :clinic_day_settings do |t|
      t.integer :day_of_week, null: false  # 0=Sunday, 1=Monday, etc.
      t.boolean :is_open,     null: false, default: true
      t.string  :open_time,   null: false, default: "09:00"
      t.string  :close_time,  null: false, default: "17:00"

      t.timestamps
    end

    add_index :clinic_day_settings, :day_of_week, unique: true
  end
end
