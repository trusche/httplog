# frozen_string_literal: true

require 'httparty'
class HTTPartyAdapter < HTTPBaseAdapter
  def send_get_request
    HTTParty.get(parse_uri(true).to_s, headers: @headers)
  end

  def send_head_request
    HTTParty.head(parse_uri.to_s, headers: @headers)
  end

  def send_post_request
    HTTParty.post(parse_uri.to_s, body: @data, headers: @headers)
  end
end
