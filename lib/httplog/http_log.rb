require "net/http"
require "logger"

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
    :log_compact   => false
  }

  def self.options
    @@options ||= DEFAULT_OPTIONS.clone
  end
  
  def self.reset_options!
    @@options = DEFAULT_OPTIONS.clone
  end

  def self.log(msg)
    @@options[:logger].add(@@options[:severity]) { "[httplog] #{msg}" }
  end

end

module Net

  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)

      if started? && !HttpLog.options[:compact_log]
        if HttpLog.options[:log_request]
          HttpLog::log("Sending: #{req.method} http://#{@address}:#{@port}#{req.path}")
        end

        if HttpLog.options[:log_headers]
          req.each_header do |key,value|
            HttpLog::log("Header: #{key}: #{value}")
          end
        end

        if req.method == "POST" && HttpLog.options[:log_data]
          # A bit convoluted becase post_form uses form_data= to assign the data, so
          # in that case req.body will be empty.
          data = req.body.nil? || req.body.size == 0 ? body : req.body
          HttpLog::log("Data: #{data}")
        end
      end

      ts_start  = Time.now
      response  = orig_request(req, body, &block)
      benchmark = Time.now - ts_start

      if started?
        if HttpLog.options[:compact_log]
          HttpLog::log("#{req.method} http://#{@address}:#{@port}#{req.path} completed with status code #{response.code} in #{benchmark} seconds")
        else
          HttpLog::log("Status: #{response.code}")        if HttpLog.options[:log_status]
          HttpLog::log("Benchmark: #{benchmark} seconds") if HttpLog.options[:log_benchmark]
          HttpLog::log("Response:\n#{response.body}")     if HttpLog.options[:log_response]
        end
      end

      response
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
    alias_method :orig_request, :request
    
    def request(method, uri, *args, &block)
      if HttpLog.options[:log_request]
        HttpLog::log("Sending: #{method.to_s.upcase} #{uri}")
      end
      
      ts_start  = Time.now
      response  = orig_request(method, uri, args, block)
      benchmark = Time.now - ts_start
      
      if HttpLog.options[:compact_log]
        HttpLog::log("#{method.to_s.upcase} #{uri} completed with status code #{response.status} in #{benchmark} seconds")
      else
        HttpLog::log("Status: #{response.status}")        if HttpLog.options[:log_status]
        HttpLog::log("Benchmark: #{benchmark} seconds") if HttpLog.options[:log_benchmark]
        HttpLog::log("Response:\n#{response.body}")     if HttpLog.options[:log_response]
      end
      
      response
    end
  end
end
