# app/jobs/send_appointment_reminders_job.rb

class SendAppointmentRemindersJob < ApplicationJob
  queue_as :default  # Or :low_priority, etc.

  def perform
    # 1) Get all unsent, due reminders
    due_reminders = AppointmentReminder.unsent.where("send_at <= ?", Time.current)

    due_reminders.find_each do |reminder|
      # 2) Attempt sending
      send_reminder(reminder)

      # 3) Mark as sent to avoid repeated sends
      reminder.mark_sent!
    end
  end

  private

  def send_reminder(reminder)
    appt = reminder.appointment
    user = appt.dependent ? appt.dependent.user : appt.user

    # If user has no phone number AND the reminder is SMS => skip. 
    # If user has phone but no email => skip email. 
    # In a real app, you'd handle edge cases carefully.

    # Decide the channels
    case reminder.delivery_method
    when "email"
      send_email_reminder(appt, user)
    when "sms"
      send_sms_reminder(appt, user)
    when "both"
      send_email_reminder(appt, user)
      send_sms_reminder(appt, user)
    end
  end

  def send_email_reminder(appointment, user)
    # You can create a special mailer or reuse AppointmentMailer with a new method
    ReminderMailer.reminder_email(appointment, user).deliver_later
  end

  def send_sms_reminder(appointment, user)
    return if user.phone.blank?

    message_body = "Hi #{user.first_name}, this is a reminder for your appointment on " \
                  "#{appointment.appointment_time.in_time_zone.strftime('%B %d at %I:%M %p')}"

    TwilioClient.send_text_message(
      to:   user.phone,
      body: message_body
    )

    # Example Twilio usage
    # return if user.phone.blank?

    # twilio_sid  = ENV['TWILIO_ACCOUNT_SID']
    # twilio_token = ENV['TWILIO_AUTH_TOKEN']
    # from_number  = ENV['TWILIO_PHONE_NUMBER']

    # client = Twilio::REST::Client.new(twilio_sid, twilio_token)
    # message_body = "Hi #{user.first_name}, this is a reminder for your appointment on " \
    #                "#{appointment.appointment_time.in_time_zone.strftime('%B %d at %I:%M %p')}"

    # begin
    #   client.messages.create(
    #     from: from_number,
    #     to:   user.phone,       # Must be in E.164 format, e.g. "+15551234567"
    #     body: message_body
    #   )
    # rescue => e
    #   Rails.logger.error "Failed to send SMS: #{e.message}"
    # end
  end
end
