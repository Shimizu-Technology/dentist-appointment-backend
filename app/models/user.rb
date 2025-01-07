# app/models/user.rb
class User < ApplicationRecord
  # If you store password for normal users
  # But phone_only users won't have a password
  has_secure_password validations: false

  has_many :dependents, dependent: :destroy
  has_many :appointments

  validates :role, presence: true

  # Only require email if not phone_only
  validates :email, presence: true, unless: :phone_only?
  validates :email, uniqueness: true, allow_blank: true

  validate :require_password_unless_phone_only

  def admin?
    role == "admin"
  end

  def phone_only?
    self[:phone_only] || role == 'phone_only'
  end

  private

  def require_password_unless_phone_only
    return if phone_only?
    if password_digest.blank?
      errors.add(:password, "can't be blank for a non-phone-only user")
    end
  end
end
