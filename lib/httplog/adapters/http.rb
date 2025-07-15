# frozen_string_literal: true

if defined?(::HTTP)
  module HttpLog
    module HTTPClientInstrumentation
      %w[make_request perform].each do |request_method|
        define_method request_method do |req, options|
          bm = Benchmark.realtime do
            @response = super(req, options)
          end

          uri = req.uri
          if HttpLog.url_approved?(uri)
            body = if defined?(::HTTP::Request::Body)
                     req.body.respond_to?(:source) ? req.body.source : req.body.instance_variable_get(:@body)
                   else
                     req.body
                   end

            HttpLog.call(
              method: req.verb,
              url: uri,
              request_body: body,
              request_headers: req.headers,
              response_code: @response.code,
              response_body: @response.body,
              response_headers: @response.headers,
              benchmark: bm,
              encoding: @response.headers['Content-Encoding'],
              content_type: @response.headers['Content-Type'],
              mask_body: HttpLog.masked_body_url?(uri)
            )

            body.rewind if body.respond_to?(:rewind)
          end

          @response
        end
      end
    end

    module HTTPConnectionInstrumentation
      def initialize(req, options)
        HttpLog.log_connection(req.uri.host, req.uri.port) if HttpLog.url_approved?(req.uri)
        super
      end
    end
  end

  HttpLog::Utils::MonkeyPatcher.register_patch(:http_client) do
    ::HTTP::Client.prepend(HttpLog::HTTPClientInstrumentation)
    ::HTTP::Connection.prepend(HttpLog::HTTPConnectionInstrumentation)
  end
end
