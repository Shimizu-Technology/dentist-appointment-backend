class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dentist
  belongs_to :appointment_type
  belongs_to :dependent, optional: true

  has_many :appointment_reminders, dependent: :destroy

  before_create :set_default_status
  before_create :default_checked_in

  # Optional: auto-create reminders
  after_create :create_appointment_reminders

  # Validations
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

  def create_appointment_reminders
    local_appt = appointment_time.in_time_zone(Rails.configuration.time_zone)

    day_of_8am = local_appt.change(hour: 8, min: 0, sec: 0)
    day_before_8am = day_of_8am - 1.day

    AppointmentReminder.create!(appointment_id: id, send_at: day_of_8am.utc)
    AppointmentReminder.create!(appointment_id: id, send_at: day_before_8am.utc)
  end

  # ----------------------------------------------------------------
  # 1) Check if the clinic is closed that day (via ClinicDaySetting or ClosedDay)
  # ----------------------------------------------------------------
  def clinic_not_closed_on_this_date
    wday = appointment_time.wday

    # 1A) Check if there's a day setting at all
    day_setting = ClinicDaySetting.find_by(day_of_week: wday)
    if day_setting.nil? || day_setting.is_open == false
      errors.add(:base, "Clinic is closed on that day (wday=#{wday}).")
      return
    end

    # 1B) Check if specifically closed by a ClosedDay record
    if ClosedDay.exists?(date: appointment_time.to_date)
      errors.add(:base, "The clinic is closed on #{appointment_time.to_date}.")
    end
  end

  # ----------------------------------------------------------------
  # 2) Check the appointment time is within open_time..close_time
  # ----------------------------------------------------------------
  def within_clinic_hours
    wday = appointment_time.wday
    day_setting = ClinicDaySetting.find_by(day_of_week: wday)

    return if day_setting.nil? # if no record or is_open==false, it’s covered above.

    open_parts  = day_setting.open_time.split(':').map(&:to_i)   # [9, 0], etc.
    close_parts = day_setting.close_time.split(':').map(&:to_i)  # [17, 0], etc.

    appt_local = appointment_time.in_time_zone(Rails.configuration.time_zone)
    date_str   = appt_local.strftime('%Y-%m-%d')

    open_dt  = Time.zone.parse("#{date_str} #{open_parts[0]}:#{open_parts[1]}")
    close_dt = Time.zone.parse("#{date_str} #{close_parts[0]}:#{close_parts[1]}")

    unless appt_local >= open_dt && appt_local < close_dt
      errors.add(:base, "Appointment time must be between #{day_setting.open_time} and #{day_setting.close_time}.")
    end
  end

  # ----------------------------------------------------------------
  # 3) Check dentist unavailability
  # ----------------------------------------------------------------
  def dentist_not_unavailable
    blocks = DentistUnavailability.where(dentist_id: dentist_id, date: appointment_time.to_date)
    appointment_end = appointment_time + (appointment_type&.duration || 30).minutes

    blocks.each do |block|
      block_start = Time.zone.parse("#{block.date} #{block.start_time}")
      block_end   = Time.zone.parse("#{block.date} #{block.end_time}")

      if appointment_time < block_end && appointment_end > block_start
        errors.add(:base, "Dentist is unavailable at that time.")
        break
      end
    end
  end

  # ----------------------------------------------------------------
  # 4) Check overlapping appointments for the same dentist
  # ----------------------------------------------------------------
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
