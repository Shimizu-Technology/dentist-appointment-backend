class DropClinicSettings < ActiveRecord::Migration[7.2]
  def up
    drop_table :clinic_settings, if_exists: true
  end

  def down
    # If you ever need to rollback, you can recreate the table or leave empty.
    create_table :clinic_settings do |t|
      t.string :open_time,  null: false, default: "09:00"
      t.string :close_time, null: false, default: "17:00"
      t.string :open_days,  null: false, default: "1,2,3,4,5"
      t.timestamps
    end
  end
end
