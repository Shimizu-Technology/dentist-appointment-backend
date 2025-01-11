class ClinicDaySetting < ApplicationRecord
  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :open_time,   presence: true
  validates :close_time,  presence: true

  validate :open_before_close, if: -> { is_open }

  private

  def open_before_close
    # parse "HH:MM" into times
    open_parts  = open_time.split(':').map(&:to_i)
    close_parts = close_time.split(':').map(&:to_i)

    open_dt  = Time.zone.parse("#{open_parts[0]}:#{open_parts[1]}")
    close_dt = Time.zone.parse("#{close_parts[0]}:#{close_parts[1]}")

    if close_dt <= open_dt
      errors.add(:base, "Close time must be after open time (day_of_week=#{day_of_week})")
    end
  end
end
