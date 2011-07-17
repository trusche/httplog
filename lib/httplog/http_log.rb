require "net/http"
require "logger"

module HttpLog
  
  def self.options
    @@options ||= {
      :logger       => Logger.new($stdout),
      :severity     => Logger::Severity::DEBUG,
      :log_connect  => true,
      :log_request  => true,
      :log_data     => true
    }
  end
  
  def self.log(msg)
    @@options[:logger].add(@@options[:severity]) { msg }
  end
  
end

module Net

  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)

      if HttpLog.options[:log_request]
        HttpLog::log("Sending: #{req.method} http://#{@address}:#{@port}#{req.path}")
      end
      
      if req.request_body_permitted? && HttpLog.options[:log_data] 
        HttpLog::log("Data: #{req.body}") 
      end
      
      orig_request(req, body, &block)
    end

    def connect
      HttpLog::log("Connecting: #{@address}") if HttpLog.options[:log_connect]
      orig_connect
    end
  end

end