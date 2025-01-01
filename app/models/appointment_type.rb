class AppointmentType < ApplicationRecord
  validates :name, presence: true
end
