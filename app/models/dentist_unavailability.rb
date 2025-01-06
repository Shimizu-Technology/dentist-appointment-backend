# File: app/models/dentist_unavailability.rb

class DentistUnavailability < ApplicationRecord
  belongs_to :dentist

  # Example attributes (string or time):
  # t.date   :date,       null: false
  # t.string :start_time, null: false # '09:00'
  # t.string :end_time,   null: false # '17:00'
  # t.string :reason,     null: true

  validates :date, :start_time, :end_time, presence: true
end
