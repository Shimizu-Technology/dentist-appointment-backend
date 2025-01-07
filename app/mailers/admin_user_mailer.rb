# File: app/mailers/admin_user_mailer.rb
class AdminUserMailer < ApplicationMailer
  default from: 'YourDentalApp <4lmshimizu@gmail.com>'
  # ^ Use your verified Single Sender address here

  # A basic “welcome” email
  def welcome_user(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Welcome to Our Dental Clinic!"
    )
  end
end
