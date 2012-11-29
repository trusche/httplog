require 'excon'
class TyphoeusAdapter < HTTPBaseAdapter
  def send_get_request
    Typhoeus.get(parse_uri.to_s, headers: @headers)
  end

  def send_post_request(data)
    Typhoeus.post(parse_uri.to_s, body: data, headers: @headers)
  end
end
