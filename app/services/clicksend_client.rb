# app/services/clicksend_client.rb
require 'net/http'
require 'json'
require 'base64'

class ClicksendClient
  BASE_URL = 'https://rest.clicksend.com/v3'

  def self.send_text_message(to:, body:, from: nil)
    username = ENV['CLICKSEND_USERNAME']
    api_key  = ENV['CLICKSEND_API_KEY']

    if username.blank? || api_key.blank?
      Rails.logger.error("[ClicksendClient] Missing ClickSend credentials (username or api_key).")
      return false
    end

    # 1) Prepare Basic Auth
    auth = Base64.strict_encode64("#{username}:#{api_key}")

    # 2) Build request URI
    uri = URI("#{BASE_URL}/sms/send")

    # 3) Build JSON payload
    payload = {
      messages: [
        {
          source: 'ruby_app',
          from:   from,
          body:   body,
          to:     to
        }
      ]
    }

    # Debug: show the payload
    Rails.logger.debug("[ClicksendClient] Sending SMS payload: #{payload.inspect}")

    # 4) Set up the POST request
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, {
      'Authorization' => "Basic #{auth}",
      'Content-Type'  => 'application/json'
    })
    request.body = payload.to_json

    # 5) Execute request
    begin
      response = http.request(request)
    rescue StandardError => e
      Rails.logger.error("[ClicksendClient] HTTP request failed with error: #{e.message}")
      return false
    end

    # 6) Check the response
    Rails.logger.debug("[ClicksendClient] Response code=#{response.code}, body=#{response.body}")

    if response.code.to_i == 200
      # parse JSON and check the ClickSend "response_code"
      json = JSON.parse(response.body) rescue {}
      if json["response_code"] == "SUCCESS"
        Rails.logger.info("[ClicksendClient] ClickSend SMS sent successfully to #{to}")
        true
      else
        Rails.logger.error("[ClicksendClient] ClickSend responded with error: #{response.body}")
        false
      end
    else
      Rails.logger.error("[ClicksendClient] HTTP Error from ClickSend: code=#{response.code}, body=#{response.body}")
      false
    end
  end
end
