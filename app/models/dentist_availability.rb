# app/models/dentist_availability.rb
class DentistAvailability < ApplicationRecord
  belongs_to :dentist

  validates :day_of_week, inclusion: { in: 0..6 }  # Sunday=0, Monday=1, etc.
  validates :start_time, :end_time, presence: true
end
