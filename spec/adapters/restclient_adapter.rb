# frozen_string_literal: true

require 'faraday'
class RestClientAdapter < HTTPBaseAdapter
  def send_get_request
    RestClient.get(parse_uri(true).to_s, @headers)
  end

  def send_head_request
    RestClient.head(parse_uri.to_s, @headers)
  end

  def send_post_request
    RestClient.post(parse_uri.to_s, @data, @headers)
  end

  def send_post_form_request
    RestClient.post(parse_uri.to_s, @params, @headers)
  end

  def send_multipart_post_request
    multipart_payload = {
      multipart: true,
      file: @params['file']
    }

    RestClient.post(parse_uri.to_s, multipart_payload, @headers)
  end
end
