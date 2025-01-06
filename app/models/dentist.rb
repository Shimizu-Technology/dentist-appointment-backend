# app/models/dentist.rb
class Dentist < ApplicationRecord
  belongs_to :specialty, optional: true

  has_many :appointments, dependent: :destroy

  has_many :dentist_unavailabilities, dependent: :destroy

  validates :first_name, :last_name, presence: true

  # Method to parse qualifications as an array from text:
  # def qualifications_list
  #   self.qualifications.to_s.split("\n")
  # end
end
