class User < ApplicationRecord
  has_secure_password
  
  has_many :dependents, dependent: :destroy
  has_many :appointments

  def admin?
    role == "admin"
  end
end
