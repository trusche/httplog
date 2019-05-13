# frozen_string_literal: true

require 'excon'
class ExconAdapter < HTTPBaseAdapter
  def send_get_request
    Excon.get(parse_uri(true).to_s, headers: @headers)
  end

  def send_head_request
    Excon.head(parse_uri.to_s, headers: @headers)
  end

  def send_post_request
    Excon.post(parse_uri.to_s, body: @data, headers: @headers)
  end
end
