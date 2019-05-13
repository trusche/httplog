# frozen_string_literal: true

class HTTPClientAdapter < HTTPBaseAdapter
  def send_get_request
    ::HTTPClient.get(parse_uri(true), header: @headers)
  end

  def send_head_request
    ::HTTPClient.head(parse_uri, header: @headers)
  end

  def send_post_request
    ::HTTPClient.post(parse_uri, body: @data, header: @headers)
  end

  def send_post_form_request
    ::HTTPClient.post(parse_uri, body: @params, header: @headers)
  end

  def send_multipart_post_request
    send_post_form_request
  end

  def self.response_should_be
    HTTP::Message
  end

  def logs_form_data?
    false
  end
end
