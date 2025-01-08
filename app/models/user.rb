# File: app/models/user.rb

class User < ApplicationRecord
  has_secure_password validations: false

  has_many :dependents, dependent: :destroy
  has_many :appointments

  validates :role, presence: true

  # Only require email if not phone_only
  validates :email, presence: true, unless: :phone_only?
  validates :email, uniqueness: true, allow_blank: true

  validate :require_password_unless_phone_only

  # Called when we first create a new user invite
  def generate_invitation_token!
    # Only set if blank:
    if self.invitation_token.blank?
      self.invitation_token   = SecureRandom.urlsafe_base64(32)
      self.invitation_sent_at = Time.current
    end
    # If no password is set (meaning we want the user to pick one), set a dummy
    if password_digest.blank?
      self.password = SecureRandom.hex(8)  # random placeholder
      self.force_password_reset = true
    end
    save!
  end

  # Called when the user finishes their invitation by picking a password
  def finish_invitation!(new_password)
    self.password = new_password
    self.invitation_token = nil
    self.invitation_sent_at = nil
    self.force_password_reset = false
    save!  # will raise ActiveRecord::RecordInvalid if fails
  end  

  def admin?
    role == "admin"
  end

  def phone_only?
    (role == 'phone_only')
  end

  private

  def require_password_unless_phone_only
    return if phone_only?
    # If the user has no stored password *and* no invitation token, we demand a password
    if password_digest.blank? && invitation_token.blank?
      errors.add(:password, "can't be blank for a non-phone-only user")
    end
  end
end
