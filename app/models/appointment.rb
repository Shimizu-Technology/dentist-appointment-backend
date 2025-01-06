# app/models/appointment.rb
class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :dentist
  belongs_to :appointment_type
  belongs_to :dependent, optional: true

  before_create :set_default_status

  validate :clinic_not_closed_on_this_date
  validate :within_clinic_hours
  validate :dentist_not_unavailable
  validate :dentist_not_already_booked

  private

  def set_default_status
    self.status ||= 'scheduled'
  end

  # -------------------------------------------
  # Instead of “Sunday is closed,” we use the
  # clinic_settings to see which days are open,
  # and also check closed_days.
  # -------------------------------------------
  def clinic_not_closed_on_this_date
    setting = ClinicSetting.singleton

    # Convert "1,2,3,4,5" => [1,2,3,4,5]
    open_days = setting.open_days.split(',').map(&:to_i)

    # 0=Sunday, 1=Monday, 2=Tuesday, ...
    wday = appointment_time.wday

    # if wday not in the array of open days, fail
    unless open_days.include?(wday)
      errors.add(:base, "Clinic is closed on that day (wday=#{wday}).")
      return
    end

    # Check single-day closures from the closed_days table:
    if ClosedDay.exists?(date: appointment_time.to_date)
      errors.add(:base, "The clinic is closed on #{appointment_time.to_date}.")
    end
  end

  def within_clinic_hours
    setting = ClinicSetting.singleton
    open_t  = setting.open_time   # "09:00"
    close_t = setting.close_time  # "17:00"
  
    open_hour, open_min   = open_t.split(':').map(&:to_i)
    close_hour, close_min = close_t.split(':').map(&:to_i)
  
    # Convert appointment_time to local time, if stored in UTC:
    appt_local = appointment_time.in_time_zone(Rails.configuration.time_zone)
  
    # build local open_dt, close_dt
    date_str = appt_local.strftime('%Y-%m-%d')
    open_dt  = Time.zone.parse("#{date_str} #{open_hour}:#{open_min}")
    close_dt = Time.zone.parse("#{date_str} #{close_hour}:#{close_min}")
  
    unless (appt_local >= open_dt && appt_local < close_dt)
      errors.add(:base, "Appointment time must be between #{open_t} and #{close_t}.")
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
