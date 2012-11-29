require "ethon"
class EthonAdapter < HTTPBaseAdapter
  def send_get_request
    easy = Ethon::Easy.new
    easy.http_request(parse_uri.to_s, :get, { headers: @headers })
    easy.perform
  end

  def send_post_request(data)
    easy = Ethon::Easy.new
    easy.http_request(parse_uri.to_s, :post, { headers: @headers, body: data })
    easy.perform
  end
end
