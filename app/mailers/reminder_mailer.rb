# app/mailers/reminder_mailer.rb
class ReminderMailer < ApplicationMailer
  default from: 'YourDentalApp <4lmshimizu@gmail.com>'

  def reminder_email(appointment, user)
    @appointment = appointment
    @user = user

    # e.g. link to the appointment
    @appointment_url = "#{Rails.application.config.x.frontend_url}/appointments/#{appointment.id}"

    mail(
      to: user.email,
      subject: "Appointment Reminder for #{appointment.appointment_time.strftime('%b %d')}"
    )
  end
end
