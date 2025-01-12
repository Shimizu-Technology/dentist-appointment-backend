# File: app/jobs/send_appointment_reminders_job.rb

class SendAppointmentRemindersJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.debug("[SendAppointmentRemindersJob] Looking for unsent reminders due <= #{Time.current}")
    due_reminders = AppointmentReminder.unsent
                                       .where("send_at <= ?", Time.current)

    Rails.logger.debug("[SendAppointmentRemindersJob] Found #{due_reminders.size} reminders.")

    due_reminders.find_each do |reminder|
      Rails.logger.debug("[SendAppointmentRemindersJob] --> Sending reminder ID=#{reminder.id}, AppointmentID=#{reminder.appointment_id}.")
      send_reminder(reminder)

      Rails.logger.debug("[SendAppointmentRemindersJob] --> Marking reminder ID=#{reminder.id} as sent.")
      reminder.mark_sent!
    end

    Rails.logger.debug("[SendAppointmentRemindersJob] Done processing reminders.")
  end

  private

  def send_reminder(reminder)
    appointment = reminder.appointment
    user        = appointment.user

    # If the user is dependent => use parent's phone instead
    phone_number = if user.dependent? && user.parent_user.present?
      user.parent_user.phone
    else
      user.phone
    end

    if phone_number.blank?
      Rails.logger.warn("[SendAppointmentRemindersJob] Skipping reminder ID=#{reminder.id} - no valid phone on file (for user or parent).")
      return
    end

    # Create a user-friendly time string
    appt_time_str = appointment.appointment_time.strftime('%B %d at %I:%M %p')
    message_body = <<~TEXT.squish
      Hi #{user.first_name},
      this is a reminder from ISA Dental for your appointment on #{appt_time_str}.
      If you need to reschedule or cancel, please call us at (671) 646-7982
      or visit our website for more options.
    TEXT

    Rails.logger.debug("[SendAppointmentRemindersJob] Attempting to send SMS to #{phone_number} (ReminderID=#{reminder.id}).")

    success = ClicksendClient.send_text_message(
      to:   phone_number,
      body: message_body
    )

    unless success
      Rails.logger.error("[SendAppointmentRemindersJob] Failed to send ClickSend SMS to #{phone_number} (ReminderID=#{reminder.id}).")
    end
  end
end
