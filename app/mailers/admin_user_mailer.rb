# File: app/mailers/admin_user_mailer.rb
class AdminUserMailer < ApplicationMailer
  default from: 'YourDentalApp <4lmshimizu@gmail.com>'

  # Example: Invitation Email
  def invitation_email(user)
    @user = user

    # 1) Grab the base URL from config.x.frontend_url
    base_frontend_url = Rails.application.config.x.frontend_url
    
    # 2) Generate the invitation link dynamically
    #    e.g. https://your-frontend.com/finish-invitation?token=<token>
    @invitation_url   = "#{base_frontend_url}/finish-invitation?token=#{@user.invitation_token}"

    mail(
      to: @user.email,
      subject: "Welcome to Our Dental Clinic! Please finish creating your account"
    )
  end

  # Example: "Welcome" Email
  def welcome_user(user)
    @user = user
    mail(
      to: @user.email,
      subject: "Welcome to Our Dental Clinic!"
    )
  end
end
