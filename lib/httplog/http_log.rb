require "net/http"
require "logger"

module HttpLog
  
  @@logger = nil
  @@severity = nil
  
  def self.logger=(logger)
    @@logger = logger
  end
  
  def self.severity=(severity)
    @@severity = severity
  end
  
  def self.logger
    @@logger ||=  Logger.new($stdout)
  end
  
  def self.severity
    @@severity ||= Logger::Severity::DEBUG
  end  
  
end

module Net

  class HTTP
    alias_method(:orig_request, :request) unless method_defined?(:orig_request)
    alias_method(:orig_connect, :connect) unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)
      HttpLog.logger.add(HttpLog.severity) { "Sending: #{req.method} http://#{@address}:#{@port}#{req.path}" }
      HttpLog.logger.add(HttpLog.severity) { "Body: #{req.body}" unless req.body.nil? }
      orig_request(req, body, &block)
    end

    def connect
      HttpLog.logger.add(HttpLog.severity) { "Connecting: #{@address}" }
      orig_connect
    end
  end

end