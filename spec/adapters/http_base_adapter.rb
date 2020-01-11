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

  def parse_uri(query = false)
    uri = "#{@protocol}://#{@host}:#{@port}#{@path}"
    uri = [uri, safe_query_string(@data)].compact.join('?') if query
    URI.parse(uri)
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

  def safe_query_string(data)
    return nil unless data

    data.to_s.split('&').map do |pair|
      pair.split('=', 2).map do |token|
        CGI.escape(token.to_s)
      end.join('=')
    end.join('&')
  end
end
