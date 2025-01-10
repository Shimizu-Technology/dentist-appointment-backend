# app/jobs/send_appointment_reminders_job.rb

class SendAppointmentRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # 1) Fetch all reminders that are unsent and due
    Rails.logger.debug("[SendAppointmentRemindersJob] Looking for unsent reminders due <= #{Time.current}")
    due_reminders = AppointmentReminder.unsent
                                       .where("send_at <= ?", Time.current)

    Rails.logger.debug("[SendAppointmentRemindersJob] Found #{due_reminders.size} reminders.")

    due_reminders.find_each do |reminder|
      # 2) Send
      Rails.logger.debug("[SendAppointmentRemindersJob] --> Sending reminder ID=#{reminder.id}, AppointmentID=#{reminder.appointment_id}.")
      send_reminder(reminder)

      # 3) Mark as sent
      Rails.logger.debug("[SendAppointmentRemindersJob] --> Marking reminder ID=#{reminder.id} as sent.")
      reminder.mark_sent!
    end

    Rails.logger.debug("[SendAppointmentRemindersJob] Done processing reminders.")
  end

  private

  def send_reminder(reminder)
    appointment = reminder.appointment
    user = appointment.user

    # If user has no phone number, skip
    if user.phone.blank?
      Rails.logger.warn("[SendAppointmentRemindersJob] Skipping reminder ID=#{reminder.id} - user #{user.id} has no phone on file.")
      return
    end

    # Create a user-friendly time string
    appt_time_str = appointment.appointment_time.strftime('%B %d at %I:%M %p')

    # Build the SMS body
    message_body = <<~TEXT.squish
      Hi #{user.first_name}, 
      this is a reminder from ISA Dental for your appointment on #{appt_time_str}.
      If you need to reschedule or cancel, please call us at (671) 646-7982
      or visit #{Rails.application.config.x.frontend_url} for more options.
    TEXT

    Rails.logger.debug("[SendAppointmentRemindersJob] Attempting to send SMS to #{user.phone} (ReminderID=#{reminder.id}).")

    success = ClicksendClient.send_text_message(
      to:   user.phone,
      body: message_body
    )

    unless success
      Rails.logger.error("[SendAppointmentRemindersJob] Failed to send ClickSend SMS to #{user.phone} (ReminderID=#{reminder.id}).")
    end
  end
end
