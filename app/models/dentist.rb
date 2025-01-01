# app/models/dentist.rb
class Dentist < ApplicationRecord
  has_many :appointments, dependent: :destroy
  has_many :dentist_availabilities, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :specialty, presence: true
end
