class HTTPBaseAdapter
  def initialize(host, port, path, protocol = 'http')
    @host = host
    @port = port
    @path = path
    @protocol = protocol
    @headers = { "accept" => "*/*", "foo" => "bar" }
    @data = "foo=bar&bar=foo"
    @params = {'foo' => 'bar', 'bar' => 'foo'}
  end

  def parse_uri
    URI.parse("#{@protocol}://#{@host}:#{@port}#{@path}")
  end

  def send_get_request
  end

  def send_post_request
  end

  def send_post_form_request
  end
end
