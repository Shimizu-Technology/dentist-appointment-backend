class CreateDentistAvailabilities < ActiveRecord::Migration[7.2]
  def change
    create_table :dentist_availabilities do |t|
      t.references :dentist, null: false, foreign_key: true
      t.integer :day_of_week, null: false         # 0=Sun, 1=Mon, 2=Tue, ...
      t.string :start_time, null: false           # e.g. "09:00"
      t.string :end_time, null: false             # e.g. "17:00"

      t.timestamps
    end
  end
end
