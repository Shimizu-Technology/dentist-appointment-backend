# app/models/clinic_setting.rb
class ClinicSetting < ApplicationRecord
  # Example validations if desired:
  # validate :open_time_before_close_time

  def self.singleton
    # ensure there's exactly 1 row in the table, or create it on the fly
    first_or_create!(
      open_time:  "09:00",
      close_time: "17:00",
      open_days:  "1,2,3,4,5"  # Monday=1 to Friday=5 by default
    )
  end
end
