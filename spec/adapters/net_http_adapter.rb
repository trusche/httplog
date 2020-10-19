# frozen_string_literal: true

class NetHTTPAdapter < HTTPBaseAdapter
  def send_get_request
    path = @path
    path = encoded_uri(@path, @data) if @data
    Net::HTTP.get_response(@host, path, @port)
  end

  def send_head_request
    Net::HTTP.new(@host, @port).head(@path, @headers)
  end

  def send_post_request
    Net::HTTP.new(@host, @port).post(@path, @data, @headers)
  end

  def send_post_form_request
    Net::HTTP.post_form(parse_uri, @params)
  end

  def self.response_string_for(response)
    response.body
  end
end
