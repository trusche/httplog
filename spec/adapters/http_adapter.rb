# frozen_string_literal: true

require 'http'
class HTTPAdapter < HTTPBaseAdapter
  def send_get_request
    client.get(parse_uri(true).to_s)
  end

  def send_head_request
    client.head(parse_uri.to_s)
  end

  def send_post_request
    client.post(parse_uri.to_s, body: @data)
  end

  def send_post_form_request
    client.post(parse_uri.to_s, form: @params)
  end

  private

  def client
    method_name = respond_to?(:with_headers) ? :with_headers : :headers
    ::HTTP.send(method_name, @headers)
  end
end
