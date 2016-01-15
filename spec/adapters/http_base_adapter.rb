class HTTPBaseAdapter
  def initialize(host, port, path, headers, data, params, protocol = 'http')
    @host = host
    @port = port
    @path = path
    @headers = headers
    @data = data
    @params = params
    @protocol = protocol
  end

  def logs_data?
    true
  end

  def parse_uri
    URI.parse("#{@protocol}://#{@host}:#{@port}#{@path}")
  end

  def expected_response_body
    "\n<html>"
  end

  def self.is_libcurl?
    false
  end

  def self.should_log_headers?
    true
  end
end
