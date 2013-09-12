class HTTPClientAdapter < HTTPBaseAdapter
  def send_get_request
    ::HTTPClient.get(parse_uri, header: @headers)
  end

  def send_post_request
    ::HTTPClient.post(parse_uri, body: @data, header: @headers)
  end

  def send_post_form_request(params)
    ::HTTPClient.post_content(parse_uri, params, @headers)
  end

  def self.response_should_be
    HTTP::Message
  end
end
