# app/models/appointment_reminder.rb
class AppointmentReminder < ApplicationRecord
  belongs_to :appointment

  validates :send_at, presence: true
  validates :delivery_method, inclusion: { in: %w[email sms both] }

  scope :unsent, -> { where(sent: false) }

  # Helper method: checks if it’s time to send the reminder
  def ready_to_send?
    !sent && send_at <= Time.current
  end

  # Mark as sent
  def mark_sent!
    update!(sent: true, sent_at: Time.current)
  end
end
