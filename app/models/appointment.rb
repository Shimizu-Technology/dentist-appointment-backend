# File: app/models/appointment.rb

class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dependent, optional: true
  belongs_to :dentist
  belongs_to :appointment_type

  before_create :set_default_status

  # Validations
  validate :no_conflicts_for_dentist
  validate :fits_into_availability

  private

  def set_default_status
    self.status ||= 'scheduled'
  end

  # ----------------------------------------------------------------------
  # 1) Prevent Overlapping with Other Appointments for this Dentist
  #
  # We only re-check for overlaps if:
  #  - The dentist changes, or
  #  - The appointment_time changes, or
  #  - The appointment_type changes to a different duration.
  # ----------------------------------------------------------------------
  def no_conflicts_for_dentist
    # (A) Figure out the old vs. new duration
    old_duration = if appointment_type_id_changed?
      # If appointment_type_id changed, look up the previous ID
      old_type_id = appointment_type_id_was
      AppointmentType.find_by(id: old_type_id)&.duration || 30
    else
      # If appointment_type_id is not changing, then there's no "previous" ID
      appointment_type&.duration || 30
    end

    new_duration = appointment_type&.duration || 30

    # (B) If nothing that affects timeslot changed, skip the conflict check
    unless will_save_change_to_dentist_id? ||
           will_save_change_to_appointment_time? ||
           (old_duration != new_duration)
      return
    end

    # (C) Perform the overlap check
    this_start = appointment_time
    this_end   = this_start + new_duration.minutes

    # Get other scheduled appts for the same dentist, excluding self
    other_appointments = Appointment.where(dentist_id: dentist_id, status: 'scheduled')
                                    .where.not(id: self.id)
                                    .includes(:appointment_type)

    other_appointments.each do |other|
      other_duration = other.appointment_type&.duration || 30
      other_start    = other.appointment_time
      other_end      = other_start + other_duration.minutes

      # Standard overlap check: (startA < endB) && (endA > startB)
      if this_start < other_end && this_end > other_start
        errors.add(:base, 'Dentist is already booked at that time.')
        break
      end
    end
  end

  # ----------------------------------------------------------------------
  # 2) Ensure Appointment Fits Entirely into the Dentist’s Available Window
  # ----------------------------------------------------------------------
  def fits_into_availability
    return if appointment_time.blank?

    day_index = appointment_time.wday
    availability = DentistAvailability.find_by(
      dentist_id: dentist_id,
      day_of_week: day_index
    )

    if availability.blank?
      errors.add(:base, "Dentist is not available on that day.")
      return
    end

    # Build the actual times for that date
    day_str   = appointment_time.strftime('%Y-%m-%d') 
    avl_start = Time.parse("#{day_str} #{availability.start_time}")
    avl_end   = Time.parse("#{day_str} #{availability.end_time}")

    duration_minutes = appointment_type&.duration || 30
    this_start = appointment_time
    this_end   = this_start + duration_minutes.minutes

    # Ensure [this_start, this_end) is within [avl_start, avl_end)
    if this_start < avl_start || this_end > avl_end
      errors.add(:base, "Appointment extends beyond the dentist's available window.")
    end
  end
end
