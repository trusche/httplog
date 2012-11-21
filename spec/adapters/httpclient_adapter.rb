class HTTPClientAdapter < HTTPBaseAdapter
  def send_get_request
    ::HTTPClient.get(parse_uri)
  end

  def send_post_request(data)
    ::HTTPClient.post(parse_uri, data)
  end

  def send_post_form_request(params)
    ::HTTPClient.post_content(parse_uri, params)
  end
end
