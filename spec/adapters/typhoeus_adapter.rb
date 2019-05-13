# frozen_string_literal: true

require 'excon'
class TyphoeusAdapter < HTTPBaseAdapter
  def send_get_request
    Typhoeus.get(parse_uri(true).to_s, headers: @headers)
  end

  def send_head_request
    Typhoeus.head(parse_uri.to_s, headers: @headers)
  end

  def send_post_request
    Typhoeus.post(parse_uri.to_s, body: @data, headers: @headers)
  end

  def send_post_form_request
    Typhoeus.post(parse_uri.to_s, body: @params, headers: @headers)
  end

  def send_multipart_post_request
    send_post_form_request
  end

  def self.is_libcurl?
    true
  end
end
