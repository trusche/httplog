require 'http'
class HTTPAdapter < HTTPBaseAdapter
  def send_get_request
    client.get(parse_uri.to_s)
  end

  def send_post_request
    client.post(parse_uri.to_s, body: @data)
  end

  def send_post_form_request
    client.post(parse_uri.to_s, form: @params)
  end

  private

  def client
    ::HTTP.with_headers(@headers)
  end
end
