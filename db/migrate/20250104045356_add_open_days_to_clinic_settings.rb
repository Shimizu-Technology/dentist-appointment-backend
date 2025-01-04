class AddOpenDaysToClinicSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :clinic_settings, :open_days, :string, null: false, default: "1,2,3,4,5"
  end
end
