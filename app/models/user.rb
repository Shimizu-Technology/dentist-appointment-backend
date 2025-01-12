# File: app/models/user.rb

class User < ApplicationRecord
  has_secure_password validations: false

  before_validation :normalize_email

  belongs_to :parent_user,
             class_name: 'User',
             optional: true

  has_many :child_users,
           class_name: 'User',
           foreign_key: 'parent_user_id',
           dependent: :nullify

  has_many :appointments, dependent: :destroy

  validates :role, presence: true

  # If not phone_only and not is_dependent => require email
  validates :email, presence: true, unless: -> { phone_only? || is_dependent }

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

  def dependent?
    is_dependent
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
    self.email = nil if email.blank?
  end

  def require_password_unless_phone_only
    return if phone_only? || is_dependent
    return if invitation_token.present?

    if password_digest.blank?
      errors.add(:password, "can't be blank for a non-phone-only user")
    end
  end
end
