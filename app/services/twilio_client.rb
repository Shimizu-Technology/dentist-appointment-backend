# File: app/services/twilio_client.rb
require 'twilio-ruby'

class TwilioClient
  def self.send_text_message(to:, body:)
    if Rails.env.production?
      # -------------------------------
      # REAL Twilio code
      # -------------------------------
      account_sid = ENV['TWILIO_ACCOUNT_SID']
      auth_token  = ENV['TWILIO_AUTH_TOKEN']
      from_number = ENV['TWILIO_PHONE_NUMBER']

      client = Twilio::REST::Client.new(account_sid, auth_token)
      message = client.messages.create(
        from: from_number,
        to:   to,  # E.164 format e.g. +15551234567
        body: body
      )
      Rails.logger.info "SMS Sent! SID: #{message.sid}, status: #{message.status}"
      message

    else
      # -------------------------------
      # FAKE / DUMMY code in dev/test
      # -------------------------------
      Rails.logger.info "Pretending to send SMS in #{Rails.env} to #{to.inspect}"
      Rails.logger.info "Message body: #{body.inspect}"
      # Return a pretend object or just nil
      OpenStruct.new(sid: 'FAKE_SID', status: 'pretended')
    end
  end

  # (Optional) for MMS:
  def self.send_mms_message(to:, body:, media_url:)
    if Rails.env.production?
      # Real Twilio code as above
    else
      Rails.logger.info "Pretending to send MMS to #{to.inspect} with body: #{body.inspect}, media: #{media_url}"
      OpenStruct.new(sid: 'FAKE_SID', status: 'pretended')
    end
  end
end
