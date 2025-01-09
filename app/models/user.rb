# File: app/models/user.rb

class User < ApplicationRecord
  has_secure_password validations: false

  # Downcase the email before validation/save:
  before_validation :downcase_email

  has_many :dependents, dependent: :destroy
  has_many :appointments

  # Make sure role is present, etc.
  validates :role, presence: true

  # Email must be unique in a case-insensitive way:
  validates :email, presence: true, unless: :phone_only?
  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true

  validate :require_password_unless_phone_only

  # Called when we first create a new user invite
  def generate_invitation_token!
    if self.invitation_token.blank?
      self.invitation_token   = SecureRandom.urlsafe_base64(32)
      self.invitation_sent_at = Time.current
    end
    # If no password is set, assign placeholder
    if password_digest.blank?
      self.password = SecureRandom.hex(8)
      self.force_password_reset = true
    end
    save!
  end

  # Called when user completes invitation
  def finish_invitation!(new_password)
    self.password = new_password
    self.invitation_token = nil
    self.invitation_sent_at = nil
    self.force_password_reset = false
    save!
  end  

  def admin?
    role == "admin"
  end

  def phone_only?
    role == 'phone_only'
  end

  private

  # Convert the email to lowercase on save, so all stored emails are consistent
  def downcase_email
    self.email = email.downcase.strip if email.present?
  end

  def require_password_unless_phone_only
    return if phone_only?
    if password_digest.blank? && invitation_token.blank?
      errors.add(:password, "can't be blank for a non-phone-only user")
    end
  end
end
