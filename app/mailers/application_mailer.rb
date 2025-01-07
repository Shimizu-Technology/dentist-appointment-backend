# File: app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: '4lmshimizu@gmail.com'  # or override in child mailers
  layout 'mailer'
end
