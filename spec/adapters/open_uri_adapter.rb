# frozen_string_literal: true

class OpenUriAdapter < HTTPBaseAdapter
  def send_get_request
    URI.open(parse_uri(true), **@headers)
  end

  def expected_response_body
    ' (not available yet)'
  end

  def logs_data?
    false
  end

  def self.response_string_for(response)
    response.string
  end
end
