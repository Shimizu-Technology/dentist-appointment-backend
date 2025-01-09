# File: app/mailers/appointment_mailer.rb
class AppointmentMailer < ApplicationMailer
  default from: 'YourDentalApp <4lmshimizu@gmail.com>'

  # Called after a successful create to confirm the booking.
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

  # Called if the appointment is updated in a way that changes
  # the date/time/dentist/type => we consider that a “reschedule.”
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

  # Called when the appointment is canceled/destroyed.
  def cancellation_notification(appointment)
    @appointment = appointment
    # Typically for a canceled appointment, the link might not be as relevant,
    # but you can still provide a link to the user's appointments page or
    # omit it. For now, let’s set it to something generic.
    @appointment_url = "#{Rails.application.config.x.frontend_url}/appointments"

    user_email = resolve_recipient_email(appointment)
    return unless user_email.present?

    mail(
      to: user_email,
      subject: "Your Appointment Has Been Canceled"
    )
  end

  private

  # If appointment.dependent_id => use the parent's (user) email.
  # Skip if phone_only or blank email.
  def resolve_recipient_email(appointment)
    actual_user = appointment.dependent ? appointment.dependent.user : appointment.user
    return nil unless actual_user
    return nil if actual_user.phone_only?
    return nil if actual_user.email.blank?

    actual_user.email
  end

  # Construct a URL to view this appointment on the frontend.
  def build_appointment_url(appointment)
    # Replace with your actual frontend route:
    # e.g. /appointments/:id or a distinct booking path, etc.
    "#{Rails.application.config.x.frontend_url}/appointments/#{appointment.id}"
  end
end
