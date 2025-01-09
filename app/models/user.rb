# File: app/models/user.rb
class User < ApplicationRecord
  has_secure_password validations: false

  # Before validation => normalize email
  before_validation :normalize_email

  has_many :dependents, dependent: :destroy
  has_many :appointments

  validates :role, presence: true

  # If NOT phone_only => email is required
  validates :email, presence: true, unless: :phone_only?
  # If they do provide an email, it must be unique (case-insensitive).
  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true

  validate :require_password_unless_phone_only

  # Called when we first create a new user invite
  def generate_invitation_token!
    # Skip if phone_only or no email
    if self.email.present? && !phone_only?
      self.invitation_token   = SecureRandom.urlsafe_base64(32)
      self.invitation_sent_at = Time.current
      # If no password is set yet, assign a temporary random password
      if password_digest.blank?
        self.password = SecureRandom.hex(8)
        self.force_password_reset = true
      end
      save!
    end
  end

  # Called when user completes invitation
  def finish_invitation!(new_password)
    self.password             = new_password
    self.invitation_token     = nil
    self.invitation_sent_at   = nil
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

  def normalize_email
    # If email is present, strip + downcase
    self.email = email.to_s.strip.downcase if email.present?
    # Convert blank to nil so the partial index sees it as truly "no email"
    self.email = nil if email.blank?
  end

  def require_password_unless_phone_only
    return if phone_only?
    if password_digest.blank? && invitation_token.blank?
      errors.add(:password, "can't be blank for a non-phone-only user")
    end
  end
end
