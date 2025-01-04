class ClosedDay < ApplicationRecord
  validates :date, presence: true, uniqueness: true
end
