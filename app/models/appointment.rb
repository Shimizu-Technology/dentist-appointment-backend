class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dependent, optional: true
  belongs_to :dentist
  belongs_to :appointment_type

  before_create :set_default_status

  private

  def set_default_status
    self.status ||= 'scheduled'
  end
end
