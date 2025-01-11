# app/models/appointment_reminder.rb

class AppointmentReminder < ApplicationRecord
  belongs_to :appointment

  scope :unsent, -> { where(sent: false) }

  def mark_sent!
    update!(sent: true, sent_at: Time.current, status: 'sent')
  end
end
