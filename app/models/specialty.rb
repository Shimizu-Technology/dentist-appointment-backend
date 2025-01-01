# app/models/specialty.rb
class Specialty < ApplicationRecord
  has_many :dentists, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
