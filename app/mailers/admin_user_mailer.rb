# File: app/mailers/admin_user_mailer.rb
class AdminUserMailer < ApplicationMailer
  default from: 'YourDentalApp <4lmshimizu@gmail.com>'

  # Example: Invitation Email
  def invitation_email(user)
    @user = user
    # Generate the URL used in your invitation_email.html.erb
    # e.g. "http://localhost:5173/finish-invitation?token=#{user.invitation_token}"
    @invitation_url = "http://localhost:5173/finish-invitation?token=#{@user.invitation_token}"

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



# # File: app/mailers/admin_user_mailer.rb

# class AdminUserMailer < ApplicationMailer
#   default from: 'YourDentalApp <4lmshimizu@gmail.com>'
#   # Adjust “from” to your validated email

#   # New method that sends an invitation link
#   def invitation_email(user)
#     @user = user
#     return unless @user.email.present?

#     # Construct a link to your front-end’s invitation page
#     # e.g. "http://localhost:5173/finish-invitation?token=XYZ"
#     # or "https://your-dental-frontend.com/finish-invitation?token=XYZ"
#     # You can store your front-end URL in a Rails env variable
#     frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
#     @invitation_url = "#{frontend_url}/finish-invitation?token=#{@user.invitation_token}"

#     mail(
#       to: @user.email,
#       subject: "Welcome to Our Dental Clinic! Please finish creating your account"
#     )
#   end
# end
