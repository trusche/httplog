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
