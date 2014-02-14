require "net/http"
require "logger"
require "benchmark"

module HttpLog
  DEFAULT_LOGGER  = Logger.new($stdout)
  DEFAULT_OPTIONS = {
    :logger                => DEFAULT_LOGGER,
    :severity              => Logger::Severity::DEBUG,
    :log_connect           => true,
    :log_request           => true,
    :log_headers           => false,
    :log_data              => true,
    :log_status            => true,
    :log_response          => true,
    :log_benchmark         => true,
    :compact_log           => false,
    :url_whitelist_pattern => /.*/,
    :url_blacklist_pattern => nil
  }

  LOG_PREFIX = "[httplog] ".freeze

  class << self
    def options
      @@options ||= DEFAULT_OPTIONS.clone
    end

    def reset_options!
      @@options = DEFAULT_OPTIONS.clone
    end

    def url_approved?(url)
      unless options[:url_blacklist_pattern].nil?
        return false if url.to_s.match(options[:url_blacklist_pattern])
      end

      url.to_s.match(options[:url_whitelist_pattern])
    end

    def log(msg)
      options[:logger].add(options[:severity]) { LOG_PREFIX + msg }
    end

    def log_connection(host, port = nil)
      return if options[:compact_log] || !options[:log_connect]
      log("Connecting: #{[host, port].compact.join(":")}")
    end

    def log_request(method, uri)
      return if options[:compact_log] || !options[:log_request]
      log("Sending: #{method.to_s.upcase} #{uri}")
    end

    def log_headers(headers = {})
      return if options[:compact_log] || !options[:log_headers]
      headers.each do |key,value|
        log("Header: #{key}: #{value}")
      end
    end

    def log_status(status)
      return if options[:compact_log] || !options[:log_status]
      log("Status: #{status}")
    end

    def log_benchmark(seconds)
      return if options[:compact_log] || !options[:log_benchmark]
      log("Benchmark: #{seconds} seconds")
    end

    def log_body(body, encoding = nil)
      return if options[:compact_log] || !options[:log_response]
      if body.is_a?(Net::ReadAdapter)
        # open-uri wraps the response in a Net::ReadAdapter that defers reading
        # the content, so the reponse body is not available here.
        log("Response: (not available yet)")
      else
        if encoding =~ /gzip/
          sio = StringIO.new( body.to_s )
          gz = Zlib::GzipReader.new( sio )
          log("Response: (deflated)\n#{gz.read}")
        else
          log("Response:\n#{body.to_s}")
        end
      end
    end

    def log_data(data)
      return if options[:compact_log] || !options[:log_data]
      log("Data: #{data}")
    end

    def log_compact(method, uri, status, seconds)
      return unless options[:compact_log]
      status = Rack::Utils.status_code(status) unless status == /\d{3}/
      log("#{method.to_s.upcase} #{uri} completed with status code #{status} in #{seconds} seconds")
    end
  end
end
