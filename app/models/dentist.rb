# app/models/dentist.rb
class Dentist < ApplicationRecord
  belongs_to :specialty, optional: true   # optional if you allow dentist without a specialty

  has_many :appointments, dependent: :destroy
  has_many :dentist_availabilities, dependent: :destroy

  validates :first_name, :last_name, presence: true

  # Parse qualifications as an array from the text column:
  # def qualifications_list
  #   self.qualifications.to_s.split("\n") # or JSON.parse(qualifications) if storing JSON
  # end
end
