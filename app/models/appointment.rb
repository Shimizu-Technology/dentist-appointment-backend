# File: app/models/appointment.rb
class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dependent, optional: true
  belongs_to :dentist
  belongs_to :appointment_type

  before_create :set_default_status

  # Add these validations:
  validate :no_conflicts_for_dentist
  validate :fits_into_availability

  private

  def set_default_status
    self.status ||= 'scheduled'
  end

  # ----------------------------------------------------------------------
  # 1) Prevent Overlapping with Other Appointments for this Dentist
  #
  # We check if there's any existing appointment (status='scheduled')
  # that intersects our [start_time, end_time).
  # ----------------------------------------------------------------------
  def no_conflicts_for_dentist
    # How long is this appointment?
    duration_minutes = self.appointment_type&.duration || 30

    this_start = self.appointment_time
    this_end   = this_start + duration_minutes.minutes

    # We only compare to other scheduled appointments for the same dentist
    other_appointments = Appointment.where(dentist_id: dentist_id, status: 'scheduled')
                                    .where.not(id: self.id)
                                    .includes(:appointment_type)

    other_appointments.each do |other|
      other_duration  = other.appointment_type&.duration || 30
      other_start     = other.appointment_time
      other_end       = other_start + other_duration.minutes

      # Standard overlap check: (startA < endB) && (endA > startB)
      if this_start < other_end && this_end > other_start
        errors.add(:base, "Dentist is already booked at that time.")
        break  # No need to keep checking once we’ve found a conflict
      end
    end
  end

  # ----------------------------------------------------------------------
  # 2) Ensure Appointment Fits Entirely into the Dentist’s Available Window
  #
  # We look up the DentistAvailability for the same day-of-week, then confirm
  # our [start, end) range is within [availability_start, availability_end).
  # ----------------------------------------------------------------------
  def fits_into_availability
    return if appointment_time.blank?

    # (A) Day-of-week: 0=Sunday, 1=Monday, ...
    day_index = appointment_time.wday

    # Fetch the relevant record, e.g. day_of_week=1 => Monday
    availability = DentistAvailability.find_by(
      dentist_id: dentist_id,
      day_of_week: day_index
    )

    if availability.blank?
      errors.add(:base, "Dentist is not available on that day.")
      return
    end

    # (B) Convert availability to actual times for that date
    #     If availability.start_time = "09:00", we build "YYYY-MM-DD 09:00"
    day_str   = appointment_time.strftime('%Y-%m-%d')  # e.g. "2025-01-12"
    avl_start = Time.parse("#{day_str} #{availability.start_time}")
    avl_end   = Time.parse("#{day_str} #{availability.end_time}")

    # (C) Calculate the end of this appointment
    duration_minutes = self.appointment_type&.duration || 30
    this_start = self.appointment_time
    this_end   = this_start + duration_minutes.minutes

    # (D) Check if [this_start, this_end) is fully inside [avl_start, avl_end)
    if this_start < avl_start || this_end > avl_end
      errors.add(:base, "Appointment extends beyond the dentist's available window.")
    end
  end
end
