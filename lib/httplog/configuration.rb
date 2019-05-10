# frozen_string_literal: true

module HttpLog
  class Configuration
    attr_accessor :enabled,
                  :compact_log,
                  :json_log,
                  :logger,
                  :severity,
                  :prefix,
                  :log_connect,
                  :log_request,
                  :log_headers,
                  :log_data,
                  :log_status,
                  :log_response,
                  :log_benchmark,
                  :url_whitelist_pattern,
                  :url_blacklist_pattern,
                  :color,
                  :prefix_data_lines,
                  :prefix_response_lines,
                  :prefix_line_numbers,
                  :filtered_keywords

    def initialize
      @enabled               = true
      @compact_log           = false
      @json_log              = false
      @logger                = Logger.new($stdout)
      @severity              = Logger::Severity::DEBUG
      @prefix                = LOG_PREFIX
      @log_connect           = true
      @log_request           = true
      @log_headers           = false
      @log_data              = true
      @log_status            = true
      @log_response          = true
      @log_benchmark         = true
      @url_whitelist_pattern = nil
      @url_blacklist_pattern = nil
      @color                 = false
      @prefix_data_lines     = false
      @prefix_response_lines = false
      @prefix_line_numbers   = false
      @filtered_keywords     = []
    end

    # TODO: remove in 1.0.0
    def []=(key, value)
      warn 'DEPRECATION WARNING: Assignment to HttpLog.options will be removed in version 1.0.0. Please use HttpLog.configure block instead as described here: https://github.com/trusche/httplog#configuration'
      send("#{key}=", value)
    end
  end
end
