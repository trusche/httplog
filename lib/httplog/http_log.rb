# frozen_string_literal: true

require 'net/http'
require 'logger'
require 'benchmark'
require 'rainbow'
require 'rack'

module HttpLog
  LOG_PREFIX = '[httplog] '.freeze
  PARAM_MASK = '[FILTERED]'

  class BodyParsingError < StandardError; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end
    alias config configuration

    def reset!
      @configuration = nil
    end

    def configure
      yield(configuration)
      configuration.json_parser ||= ::JSON if configuration.json_log || configuration.url_masked_body_pattern
    end

    def call(options = {})
      parse_request(options)
      if config.json_log
        log_json(options)
      elsif config.graylog_formatter
        log_graylog(options)
      elsif config.compact_log
        log_compact(options[:method], options[:url], options[:response_code], options[:benchmark])
      else
        HttpLog.log_request(options[:method], options[:url])
        HttpLog.log_headers(options[:request_headers])
        HttpLog.log_data(options[:request_body])
        HttpLog.log_status(options[:response_code])
        HttpLog.log_benchmark(options[:benchmark])
        HttpLog.log_headers(options[:response_headers])
        HttpLog.log_body(options[:response_body], options[:mask_body], options[:encoding], options[:content_type])
      end
    end

    def url_approved?(url)
      return false if config.url_blacklist_pattern && url.to_s.match(config.url_blacklist_pattern)

      !config.url_whitelist_pattern || url.to_s.match(config.url_whitelist_pattern)
    end

    def masked_body_url?(url)
      config.filter_parameters.any? && config.url_masked_body_pattern && url.to_s.match(config.url_masked_body_pattern)
    end

    def log(msg)
      return unless config.enabled

      config.logger.public_send(config.logger_method, config.severity, colorize(prefix + msg.to_s))
    end

    def log_connection(host, port = nil)
      return if config.json_log || config.compact_log || !config.log_connect

      log("Connecting: #{[host, port].compact.join(':')}")
    end

    def log_request(method, uri)
      return unless config.log_request

      log("Sending: #{method.to_s.upcase} #{masked(uri)}")
    end

    def log_headers(headers = {})
      return unless config.log_headers

      masked(headers).each do |key, value|
        log("Header: #{key}: #{value}")
      end
    end

    def log_status(status)
      return unless config.log_status

      status = Rack::Utils.status_code(status) unless status == /\d{3}/
      log("Status: #{status}")
    end

    def log_benchmark(seconds)
      return unless config.log_benchmark

      log("Benchmark: #{seconds.to_f.round(6)} seconds")
    end

    def log_body(body, mask_body, encoding = nil, content_type = nil)
      return unless config.log_response

      data = parse_body(body, mask_body, encoding, content_type)

      if config.prefix_response_lines
        log('Response:')
        log_data_lines(data)
      else
        log("Response:\n#{data}")
      end
    rescue BodyParsingError => e
      log("Response: #{e.message}")
    end

    def parse_body(body, mask_body, encoding, content_type)
      raise BodyParsingError, "(not showing binary data)" unless text_based?(content_type)


      if body.is_a?(Net::ReadAdapter)
        # open-uri wraps the response in a Net::ReadAdapter that defers reading
        # the content, so the response body is not available here.
        raise BodyParsingError, '(not available yet)'
      end

      body_copy = body.dup
      body_copy = body.to_s if defined?(HTTP::Response::Body) && body.is_a?(HTTP::Response::Body)
      return nil if body_copy.nil? || body_copy.empty?


      if encoding =~ /gzip/
        begin
          sio = StringIO.new(body_copy.to_s)
          gz = Zlib::GzipReader.new(sio)
          body_copy = gz.read
        rescue Zlib::GzipFile::Error
          log("(gzip decompression failed)")
        end
      end

      result = utf_encoded(body_copy.to_s, content_type)

      if mask_body
        if content_type =~ /json/
          result = begin
                     masked_data config.json_parser.load(result)
                   rescue => e
                     'Failed to mask response body: ' + e.message
                   end
        else
          result = masked(result)
        end
      end
      result
    end

    def log_data(data)
      return unless config.log_data

      if config.prefix_data_lines
        log('Data:')
        log_data_lines(data)
      else
        log("Data: #{data}")
      end
    end

    def log_compact(method, uri, status, seconds)
      return unless config.compact_log
      status = Rack::Utils.status_code(status) unless status == /\d{3}/
      log("#{method.to_s.upcase} #{masked(uri)} completed with status code #{status} in #{seconds.to_f.round(6)} seconds")
    end

    def transform_response_code(response_code_name)
      Rack::Utils::HTTP_STATUS_CODES.detect { |_k, v| v.to_s.casecmp(response_code_name.to_s).zero? }.first
    end

    def colorize(msg)
      return msg unless config.color
      if config.color.is_a?(Hash)
        msg = Rainbow(msg).color(config.color[:color]) if config.color[:color]
        msg = Rainbow(msg).bg(config.color[:background]) if config.color[:background]
      else
        msg = Rainbow(msg).color(config.color)
      end
      msg
    rescue StandardError
      warn "HTTPLOG CONFIGURATION ERROR: #{config.color} is not a valid color"
      msg
    end

    private

    def log_json(data = {})
      return unless config.json_log

      log(
        begin
          dump_json(data)
        rescue
          data[:response_body] = "#{config.json_parser} dump failed"
          data[:request_body]  = "#{config.json_parser} dump failed"
          dump_json(data)
        end
      )
    end

    def dump_json(data)
      config.json_parser.dump(json_payload(data))
    end

    def log_graylog(data)
      result = json_payload(data)
      begin
        send_to_graylog result
      rescue
        result[:response_body] = 'Graylog JSON dump failed'
        result[:request_body]  = 'Graylog JSON dump failed'
        send_to_graylog result
      end
    end

    def send_to_graylog data
      data.compact!
      config.logger.public_send(config.logger_method, config.severity, config.graylog_formatter.call(data))
    end

    def json_payload(data = {})
      data[:response_code] = transform_response_code(data[:response_code]) if data[:response_code].is_a?(Symbol)

      parsed_body = begin
                      parse_body(data[:response_body], data[:mask_body], data[:encoding], data[:content_type])
                    rescue BodyParsingError => e
                      e.message
                    end

      if config.compact_log
        {
          method:        data[:method].to_s.upcase,
          url:           masked(data[:url]),
          response_code: data[:response_code].to_i,
          benchmark:     data[:benchmark]
        }
      else
        {
          method:           data[:method].to_s.upcase,
          url:              masked(data[:url]),
          request_body:     data[:request_body],
          request_headers:  masked(data[:request_headers].to_h),
          response_code:    data[:response_code].to_i,
          response_body:    parsed_body,
          response_headers: data[:response_headers].to_h,
          benchmark:        data[:benchmark]
        }
      end
    end

    def masked(msg, key=nil)
      return msg if config.filter_parameters.empty?
      return msg if msg.nil?

      # If a key is given, msg is just the value and can be replaced
      # in its entirety.
      return (config.filter_parameters.include?(key.downcase) ? PARAM_MASK : msg) if key

      # Otherwise, we'll parse Strings for key=value pairs,
      # for name="key"\n value...
      case msg
      when *string_classes
        config.filter_parameters.reduce(msg) do |m,key|
          scrubbed = m.to_s.encode('UTF-8', invalid: :replace, undef: :replace)
          scrubbed.to_s.gsub(/(#{key})=[^&]+/i, "#{key}=#{PARAM_MASK}")
            .gsub(/name="#{key}"\s+\K[\s\w]+/, "#{PARAM_MASK}\r\n") # multi-part Faraday
        end
      # ...and recurse over hashes
      when *hash_classes
        Hash[msg.map {|k,v| [k, masked(v, k)]}]
      else
        log "*** FILTERING NOT APPLIED BECAUSE #{msg.class} IS UNEXPECTED ***"
        msg
      end
    end

    def parse_request(options)
      return if options[:request_body].nil?

      # Downcase content-type and content-encoding because ::HTTP returns "Content-Type" and "Content-Encoding"
      headers = options[:request_headers].find_all do |header, _|
        %w[content-type Content-Type content-encoding Content-Encoding].include? header
      end.to_h.each_with_object({}) { |(k, v), h| h[k.downcase] = v }

      copy = options[:request_body].dup

      options[:request_body] = if text_based?(headers['content-type']) && options[:mask_body]
                                 begin
                                   parse_body(copy, options[:mask_body], headers['content-encoding'], headers['content-type'])
                                 rescue BodyParsingError => e
                                   log(e.message)
                                 end
                               else
                                 masked(copy).to_s
                               end
    end

    def masked_data msg
      case msg
      when Hash
        Hash[msg.map { |k, v| [k, config.filter_parameters.include?(k.downcase) ? PARAM_MASK : masked_data(v)] }]
      when Array
        msg.map { |element| masked_data(element) }
      else
        msg
      end
    end

    def string_classes
      @string_classes ||= begin
        string_classes = [String]
        string_classes << HTTP::Response::Body if defined?(HTTP::Response::Body)
        string_classes << HTTP::URI if defined?(HTTP::URI)
        string_classes << URI::HTTP if defined?(URI::HTTP)
        string_classes << HTTP::FormData::Urlencoded if defined?(HTTP::FormData::Urlencoded)
        string_classes << Addressable::URI if defined?(Addressable::URI)
        string_classes << HTTPClient::Util::AddressableURI if defined?(HTTPClient::Util::AddressableURI)
        string_classes
      end
    end

    def hash_classes
      @hash_classes ||= begin
        hash_classes = [Hash, Enumerator]
        hash_classes << HTTP::Headers if defined?(HTTP::Headers)
        hash_classes
      end
    end

    def utf_encoded(data, content_type = nil)
      charset = content_type.to_s.scan(/; charset=(\S+)/).flatten.first || 'UTF-8'
      begin
        data.force_encoding(charset)
      rescue StandardError
        data.force_encoding('UTF-8')
      end
      data.encode('UTF-8', invalid: :replace, undef: :replace)
    end

    def text_based?(content_type)
      # This is a very naive way of determining if the content type is text-based; but
      # it will allow application/json and the like without having to resort to more
      # heavy-handed checks.
      content_type =~ /^text/ ||
        content_type =~ /^application/ && !['application/octet-stream', 'application/pdf'].include?(content_type)
    end

    def log_data_lines(data)
      data.to_s.each_line.with_index do |line, row|
        if config.prefix_line_numbers
          log("#{row + 1}: #{line.chomp}")
        else
          log(line.strip)
        end
      end
    end

    def prefix
      if config.prefix.respond_to?(:call)
        config.prefix.call
      else
        config.prefix.to_s
      end
    end
  end
end
