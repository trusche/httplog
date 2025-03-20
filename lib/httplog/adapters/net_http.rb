# frozen_string_literal: true

module HttpLog
  module Net
    module HTTP
      def request(req, body = nil, &block)
        url = "http://#{@address}:#{@port}#{req.path}"

        bm = Benchmark.realtime do
          @response = super(req, body, &block)
        end
        body_stream  = req.body_stream
        request_body = if body_stream
                         body_stream.to_s # read and rewind for RestClient::Payload::Base
                         body_stream.rewind if body_stream.respond_to?(:rewind) # RestClient::Payload::Base has no method rewind
                         body_stream.read
                       elsif req.body.nil? || req.body.empty?
                         body
                       else
                         req.body
                       end

        if HttpLog.url_approved?(url) && started?
          HttpLog.call(
            method: req.method,
            url: url,
            request_body: request_body,
            request_headers: req.each_header.collect,
            response_code: @response.code,
            response_body: @response.body,
            response_headers: @response.each_header.collect,
            benchmark: bm,
            encoding: @response['Content-Encoding'],
            content_type: @response['Content-Type'],
            mask_body: HttpLog.masked_body_url?(url)
          )
        end

        @response
      end

      def connect
        HttpLog.log_connection(@address, @port) if !started? && HttpLog.url_approved?("#{@address}:#{@port}")

        super
      end
    end
  end
end

HttpLog::Utils::MonkeyPatcher.register_patch(:net_http, HttpLog::Net::HTTP, ::Net::HTTP)
