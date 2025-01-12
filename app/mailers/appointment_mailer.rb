# File: app/mailers/appointment_mailer.rb
class AppointmentMailer < ApplicationMailer
  default from: 'YourDentalApp <4lmshimizu@gmail.com>'

  def booking_confirmation(appointment)
    @appointment = appointment
    @appointment_url = build_appointment_url(appointment)

    user_email = resolve_recipient_email(appointment)
    return unless user_email.present?

    mail(
      to: user_email,
      subject: "Your Appointment Is Booked!"
    )
  end

  def reschedule_notification(appointment)
    @appointment = appointment
    @appointment_url = build_appointment_url(appointment)

    user_email = resolve_recipient_email(appointment)
    return unless user_email.present?

    mail(
      to: user_email,
      subject: "Your Appointment Has Been Rescheduled"
    )
  end

  def cancellation_notification(appointment)
    @appointment = appointment
    @appointment_url = "#{Rails.application.config.x.frontend_url}/appointments"

    user_email = resolve_recipient_email(appointment)
    return unless user_email.present?

    mail(
      to: user_email,
      subject: "Your Appointment Has Been Canceled"
    )
  end

  private

  # If user is dependent => use parent's email. Otherwise, use user’s.
  def resolve_recipient_email(appointment)
    user = appointment.user
    return nil unless user

    if user.dependent?
      parent = user.parent_user
      return nil unless parent
      return nil if parent.phone_only?
      return nil if parent.email.blank?
      return parent.email
    else
      return nil if user.phone_only?
      return nil if user.email.blank?
      user.email
    end
  end

  def build_appointment_url(appointment)
    "#{Rails.application.config.x.frontend_url}/appointments/#{appointment.id}"
  end
end
