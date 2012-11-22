require 'httparty'
class HTTPartyAdapter < HTTPBaseAdapter
  def send_get_request
    HTTParty.get(parse_uri.to_s, headers: { "accept" => "*/*", "foo" => "bar" })
  end

  def send_post_request(data)
    HTTParty.post(parse_uri.to_s, body: data)
  end
end
