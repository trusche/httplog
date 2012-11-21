require "net/http"
require "logger"
require "benchmark"

module HttpLog
  DEFAULT_LOGGER  = Logger.new($stdout)
  DEFAULT_OPTIONS = {
    :logger        => DEFAULT_LOGGER,
    :severity      => Logger::Severity::DEBUG,
    :log_connect   => true,
    :log_request   => true,
    :log_headers   => false,
    :log_data      => true,
    :log_status    => true,
    :log_response  => true,
    :log_benchmark => true,
    :compact_log   => false
  }

  class << self
    def options
      @@options ||= DEFAULT_OPTIONS.clone
    end

    def reset_options!
      @@options = DEFAULT_OPTIONS.clone
    end

    def log(msg)
      @@options[:logger].add(@@options[:severity]) { "[httplog] #{msg}" }
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

    def log_body(body)
      return if options[:compact_log] || !options[:log_response]
      if body.is_a?(Net::ReadAdapter)
        # open-uri wraps the response in a Net::ReadAdapter that defers reading
        # the content, so the reponse body is not available here.
        log("Response: (not available yet)")
      else
        log("Response:\n#{body.to_s}")
      end
    end

    def log_data(data)
      return if options[:compact_log] || !options[:log_data]
      log("Data: #{data}")
    end

    def log_compact(method, uri, status, seconds)
      return unless options[:compact_log]
      log("#{method} #{uri} completed with status code #{status} in #{seconds} seconds")
    end
  end
end

module Net
  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)

      url = "http://#{@address}:#{@port}#{req.path}"

      if started? && !HttpLog.options[:compact_log]
        HttpLog.log_request(req.method, url)
        HttpLog.log_headers(req.each_header.collect)
        # A bit convoluted becase post_form uses form_data= to assign the data, so
        # in that case req.body will be empty.
        HttpLog::log_data(req.body.nil? || req.body.size == 0 ? body : req.body) if req.method == 'POST'
      end

      bm = Benchmark.realtime do
        @response = orig_request(req, body, &block)
      end

      if started?
        HttpLog.log_compact(req.method, url, @response.code, bm)
        HttpLog.log_status(@response.code)
        HttpLog.log_benchmark(bm)
        HttpLog.log_body(@response.body)
      end

      @response
    end

    def connect
      unless started? || HttpLog.options[:compact_log]
        HttpLog::log("Connecting: #{@address}") if HttpLog.options[:log_connect]
      end
      orig_connect
    end
  end

end

if defined?(::HTTPClient)
  class HTTPClient
    private
    alias_method :orig_do_request, :do_request

    def do_request(method, uri, query, body, header, &block)
      HttpLog.log_request(method, uri)
      HttpLog.log_headers(header)
      HttpLog.log_data(body) if method == :post

      bm = Benchmark.realtime do
        @response  = orig_do_request(method, uri, query, body, header, &block)
      end

      HttpLog.log_compact(method, uri, @response.status, bm)
      HttpLog.log_status(@response.status)
      HttpLog.log_benchmark(bm)
      HttpLog.log_body(@response.body)

      @response
    end
  end
end
