# frozen_string_literal: true

require 'ethon'
class EthonAdapter < HTTPBaseAdapter
  def send_get_request
    easy = Ethon::Easy.new
    easy.http_request(parse_uri(true).to_s, :get, headers: @headers)
    easy.perform

    easy
  end

  def send_head_request
    easy = Ethon::Easy.new
    easy.http_request(parse_uri.to_s, :head, headers: @headers)
    easy.perform

    easy
  end

  def send_post_request
    easy = Ethon::Easy.new
    easy.http_request(parse_uri.to_s, :post, headers: @headers, body: @data)
    easy.perform

    easy
  end

  def self.is_libcurl?
    true
  end

  def self.response_string_for(response)
    response.response_body
  end
end
