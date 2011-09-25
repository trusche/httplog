require "net/http"
require "logger"

module HttpLog
  
  def self.options
    @@options ||= {
      :logger       => Logger.new($stdout),
      :severity     => Logger::Severity::DEBUG,
      :log_connect  => true,
      :log_request  => true,
      :log_data     => true,
      :log_status   => true,
      :log_response => true
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

      if started?
        if HttpLog.options[:log_request]
          HttpLog::log("[httplog] Sending: #{req.method} http://#{@address}:#{@port}#{req.path}")
        end
    
        if req.method == "POST" && HttpLog.options[:log_data] 
          # a bit convoluted becase post_form uses form_data= to assign the data, so 
          # in that case req.body will be empty
          data = req.body.nil? || req.body.size == 0 ? body : req.body
          HttpLog::log("[httplog] Data: #{data}") 
        end
      end
      
      response = orig_request(req, body, &block)
      
      if started?
        HttpLog::log("[httplog] Status: #{response.code}") if HttpLog.options[:log_status]
        HttpLog::log("[httplog] Response: #{response.body}") if HttpLog.options[:log_response]
      end
      
      response
    end

    def connect
      unless started?
        HttpLog::log("[httplog] Connecting: #{@address}") if HttpLog.options[:log_connect]
      end
      orig_connect
    end
  end

end