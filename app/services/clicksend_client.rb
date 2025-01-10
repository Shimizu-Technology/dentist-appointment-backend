# File: app/services/clicksend_client.rb
require 'net/http'
require 'json'
require 'base64'

class ClicksendClient
  BASE_URL = 'https://rest.clicksend.com/v3'

  def self.send_text_message(to:, body:, from: nil)
    username = ENV['CLICKSEND_USERNAME']
    api_key  = ENV['CLICKSEND_API_KEY']
    raise "Missing ClickSend credentials" if username.blank? || api_key.blank?

    # 1) Prepare Basic Auth
    auth = Base64.strict_encode64("#{username}:#{api_key}")

    # 2) Build request URI
    uri = URI("#{BASE_URL}/sms/send")

    # 3) Build JSON payload
    payload = {
      messages: [
        {
          source: 'ruby_app',  # optional, to identify your source
          from:   from,        # optional, or your dedicated number/alpha tag
          body:   body,
          to:     to
        }
      ]
    }

    # 4) Set up the POST request with headers
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, {
      'Authorization' => "Basic #{auth}",
      'Content-Type'  => 'application/json'
    })
    request.body = payload.to_json

    # 5) Execute and parse response
    response = http.request(request)

    # 6) Check if it was successful
    if response.code.to_i == 200
      json = JSON.parse(response.body) rescue {}
      if json["response_code"] == "SUCCESS"
        Rails.logger.info "ClickSend SMS sent successfully to #{to}"
        return true
      else
        Rails.logger.error "ClickSend responded with error: #{response.body}"
        return false
      end
    else
      Rails.logger.error "HTTP Error from ClickSend: #{response.code} - #{response.body}"
      return false
    end
  end
end
