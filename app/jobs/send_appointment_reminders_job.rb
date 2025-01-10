# app/jobs/send_appointment_reminders_job.rb

class SendAppointmentRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # 1) Fetch all reminders that are unsent and due
    due_reminders = AppointmentReminder.unsent
                                       .where("send_at <= ?", Time.current)

    due_reminders.find_each do |reminder|
      # 2) Send
      send_reminder(reminder)

      # 3) Mark as sent
      reminder.mark_sent!
    end
  end

  private

  def send_reminder(reminder)
    appointment = reminder.appointment
    user        = appointment.user

    # If user has no phone number, skip
    return if user.phone.blank?

    # Create a user-friendly time string
    appt_time_str = appointment.appointment_time.strftime('%B %d at %I:%M %p')

    # Build the SMS body
    # Include your clinic name, phone, and link
    message_body = <<~TEXT.squish
      Hi #{user.first_name}, 
      this is a reminder from ISA Dental for your appointment on #{appt_time_str}.
      If you need to reschedule or cancel, please call us at (671) 646-7982
      or visit #{Rails.application.config.x.frontend_url} for more options.
    TEXT

    # If you want to specify a sender:
    # success = ClicksendClient.send_text_message(to: user.phone, body: message_body, from: ENV['CLICKSEND_SENDER'])
    success = ClicksendClient.send_text_message(
      to:   user.phone,
      body: message_body
    )

    Rails.logger.error("Failed to send ClickSend SMS to #{user.phone}") unless success
  end
end
