class HTTPBaseAdapter
  def initialize(host, port, path, protocol = 'http')
    @host = host
    @port = port
    @path = path
    @protocol = protocol
    @headers = { "accept" => "*/*", "foo" => "bar" }
    @data = "foo=bar%3Azee&bar=foo"
    @params = {'foo' => 'bar', 'bar' => 'foo'}
  end

  def parse_uri
    URI.parse("#{@protocol}://#{@host}:#{@port}#{@path}")
  end

  def send_post_form_request
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
