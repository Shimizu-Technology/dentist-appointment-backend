# File: app/models/appointment.rb

class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dentist
  belongs_to :appointment_type
  belongs_to :dependent, optional: true

  # --------- NEW: Destroy associated reminders if appointment is deleted -------
  has_many :appointment_reminders, dependent: :destroy

  before_create :set_default_status
  before_create :default_checked_in

  # Optional: if you are auto-creating reminders for “day-of” + “day-before”
  after_create :create_appointment_reminders

  validate :clinic_not_closed_on_this_date
  validate :within_clinic_hours
  validate :dentist_not_unavailable
  validate :dentist_not_already_booked

  private

  def set_default_status
    self.status ||= 'scheduled'
  end

  def default_checked_in
    self.checked_in = false if checked_in.nil?
  end

  # ------------------------------------------------------------------
  # ONLY INCLUDE THIS if you want to automatically create *two* reminders:
  #   1) day before at 8:00 AM
  #   2) day of at 8:00 AM
  # Otherwise, remove or adapt to your own logic.
  # ------------------------------------------------------------------
  def create_appointment_reminders
    local_appt = appointment_time.in_time_zone(Rails.configuration.time_zone)

    # For the day-of: e.g. 8:00 AM same day
    day_of_8am = local_appt.change(hour: 8, min: 0, sec: 0)

    # For the day-before: 8:00 AM
    day_before_8am = day_of_8am - 1.day

    AppointmentReminder.create!(
      appointment_id: id,
      send_at: day_of_8am.utc
    )

    AppointmentReminder.create!(
      appointment_id: id,
      send_at: day_before_8am.utc
    )
  end

  def clinic_not_closed_on_this_date
    setting = ClinicSetting.singleton
    open_days = setting.open_days.split(',').map(&:to_i)
    wday = appointment_time.wday

    unless open_days.include?(wday)
      errors.add(:base, "Clinic is closed on that day (wday=#{wday}).")
      return
    end

    if ClosedDay.exists?(date: appointment_time.to_date)
      errors.add(:base, "The clinic is closed on #{appointment_time.to_date}.")
    end
  end

  def within_clinic_hours
    setting = ClinicSetting.singleton
    open_hour, open_min   = setting.open_time.split(':').map(&:to_i)
    close_hour, close_min = setting.close_time.split(':').map(&:to_i)

    appt_local = appointment_time.in_time_zone(Rails.configuration.time_zone)
    date_str   = appt_local.strftime('%Y-%m-%d')

    open_dt  = Time.zone.parse("#{date_str} #{open_hour}:#{open_min}")
    close_dt = Time.zone.parse("#{date_str} #{close_hour}:#{close_min}")

    unless appt_local >= open_dt && appt_local < close_dt
      errors.add(:base, "Appointment time must be between #{setting.open_time} and #{setting.close_time}.")
    end
  end

  def dentist_not_unavailable
    blocks = DentistUnavailability.where(dentist_id: dentist_id, date: appointment_time.to_date)
    appointment_end = appointment_time + (appointment_type&.duration || 30).minutes

    blocks.each do |block|
      block_start = Time.parse("#{block.date} #{block.start_time}")
      block_end   = Time.parse("#{block.date} #{block.end_time}")

      if appointment_time < block_end && appointment_end > block_start
        errors.add(:base, "Dentist is unavailable at that time.")
        break
      end
    end
  end

  def dentist_not_already_booked
    appointment_end = appointment_time + (appointment_type&.duration || 30).minutes

    overlapping = Appointment
      .where(dentist_id: dentist_id, status: 'scheduled')
      .where.not(id: id)
      .where("appointment_time < ?", appointment_end)
      .where("appointment_time + (COALESCE((SELECT duration FROM appointment_types WHERE id = appointment_type_id), 30) * interval '1 minute') > ?", appointment_time)

    if overlapping.exists?
      errors.add(:base, "Dentist already has an appointment overlapping that time.")
    end
  end
end
