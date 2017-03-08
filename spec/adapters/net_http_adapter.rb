class NetHTTPAdapter < HTTPBaseAdapter
  def send_get_request
    Net::HTTP.get_response(@host, [@path, @data].compact.join('?'), @port)
  end

  def send_head_request
    http = Net::HTTP.new(@host, @port)
    http.head(@path, @headers)
  end

  def send_post_request
    http = Net::HTTP.new(@host, @port)
    resp = http.post(@path, @data)
  end

  def send_post_form_request
    res = Net::HTTP.post_form(parse_uri, @params)
  end
end
