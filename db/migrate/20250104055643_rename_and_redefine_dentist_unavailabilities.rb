class RenameAndRedefineDentistUnavailabilities < ActiveRecord::Migration[7.2]
  def change
    rename_table :dentist_availabilities, :dentist_unavailabilities

    # Remove day_of_week; add date
    remove_column :dentist_unavailabilities, :day_of_week, :integer
    add_column :dentist_unavailabilities, :date, :date, null: false

    # start_time/end_time remain, but now they define the block on that date
    # They are already strings, so no change needed except to confirm null: false
    change_column_null :dentist_unavailabilities, :start_time, false
    change_column_null :dentist_unavailabilities, :end_time, false
  end
end
