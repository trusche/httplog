# frozen_string_literal: true

class HTTPBaseAdapter
  def initialize(options = {})
    @host     = options.fetch(:host, 'localhost')
    @port     = options.fetch(:port, 80)
    @path     = options.fetch(:path, '/')
    @headers  = options.fetch(:headers, {})
    @data     = options.fetch(:data, nil)
    @params   = options.fetch(:params, {})
    @protocol = options.fetch(:protocol, 'http')
  end

  def logs_data?
    true
  end

  def logs_form_data?
    true
  end

  def encoded_uri(uri, data) 
    [uri, URI.encode_www_form(@data.split("&").map{|pair| pair.split("=") })].join('?') 
  end

  def parse_uri(query=false)
    uri = "#{@protocol}://#{@host}:#{@port}#{@path}"
    uri = encoded_uri(uri, @data) if query && @data
    URI.parse(uri)
  end

  def expected_response_body
    "\n<html>"
  end

  def expected_full_response_body
    <<-HTML.gsub(/^      /, "").strip
      <html>
        <head>
          <title>Test Page</title>
        </head>
        <body>
          <h1>This is the test page.</h1>
        </body>
      </html>
    HTML
  end

  def self.is_libcurl?
    false
  end

  def self.should_log_headers?
    true
  end

  def self.response_string_for(response)
    response.to_s
  end
end
