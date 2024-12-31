class User < ApplicationRecord
  # Devise modules: confirmable, lockable, timeoutable, trackable, etc. if needed
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def admin?
    role == "admin"
  end
end
