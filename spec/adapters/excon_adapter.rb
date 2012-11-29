require 'excon'
class ExconAdapter < HTTPBaseAdapter
  def send_get_request
    Excon.get(parse_uri.to_s, headers: { "accept" => "*/*", "foo" => "bar" })
  end

  def send_post_request(data)
    Excon.post(parse_uri.to_s, body: data)
  end
end
