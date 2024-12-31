class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dependent
  belongs_to :dentist
  belongs_to :appointment_type
  belongs_to :user
  belongs_to :dependent, optional: true
  belongs_to :dentist
  belongs_to :appointment_type
end
