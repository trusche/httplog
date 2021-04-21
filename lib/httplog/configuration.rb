# frozen_string_literal: true

module HttpLog
  class Configuration
    attr_accessor :enabled,
                  :compact_log,
                  :json_log,
                  :graylog_formatter,
                  :logger,
                  :logger_method,
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
                  :url_masked_body_pattern,
                  :color,
                  :prefix_data_lines,
                  :prefix_response_lines,
                  :prefix_line_numbers,
                  :json_parser,
                  :filter_parameters

    def initialize
      @enabled                 = true
      @compact_log             = false
      @json_log                = false
      @graylog_formatter       = nil
      @logger                  = Logger.new($stdout)
      @logger_method           = :log
      @severity                = Logger::Severity::DEBUG
      @prefix                  = LOG_PREFIX
      @log_connect             = true
      @log_request             = true
      @log_headers             = false
      @log_data                = true
      @log_status              = true
      @log_response            = true
      @log_benchmark           = true
      @url_whitelist_pattern   = nil
      @url_blacklist_pattern   = nil
      @url_masked_body_pattern = nil
      @color                   = false
      @prefix_data_lines       = false
      @prefix_response_lines   = false
      @prefix_line_numbers     = false
      @json_parser             = nil
      @filter_parameters       = %w[password]
    end
  end
end
