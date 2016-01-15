class OpenUriAdapter < HTTPBaseAdapter
  def send_get_request
    open(parse_uri)
  end

  def expected_response_body
    " (not available yet)"
  end

  def self.should_log_headers?
    false
  end

  def logs_data?
    false
  end
end
