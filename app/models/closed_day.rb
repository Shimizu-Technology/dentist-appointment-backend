# File: app/models/closed_day.rb
class ClosedDay < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  # Possibly a :reason column

  # Example schema:
  # t.date :date, null: false
  # t.string :reason
end
