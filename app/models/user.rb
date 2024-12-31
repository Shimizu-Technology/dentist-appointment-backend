class User < ApplicationRecord
  # Devise modules: confirmable, lockable, timeoutable, trackable, etc. if needed
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :dependents, dependent: :destroy
  has_many :appointments

  def admin?
    role == "admin"
  end
end
