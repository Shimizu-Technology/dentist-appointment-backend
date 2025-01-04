# app/models/clinic_setting.rb
class ClinicSetting < ApplicationRecord
  # validations if you like
  # e.g. validate :open_time_before_close_time

  def self.singleton
    # ensure there's exactly 1 row in the table, or create it on the fly
    first_or_create!(open_time: "09:00", close_time: "17:00")
  end
end
