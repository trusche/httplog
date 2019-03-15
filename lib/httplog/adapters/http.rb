# frozen_string_literal: true

if defined?(::HTTP::Client) && defined?(::HTTP::Connection)
  module ::HTTP # rubocop:disable Style/ClassAndModuleChildren
    class Client
      request_method = respond_to?('make_request') ? 'make_request' : 'perform'
      orig_request_method = "orig_#{request_method}"
      alias_method(orig_request_method, request_method) unless method_defined?(orig_request_method)

      define_method request_method do |req, options|
        bm = Benchmark.realtime do
          @response = send(orig_request_method, req, options)
        end

        if HttpLog.url_approved?(req.uri)
          body = if defined?(::HTTP::Request::Body)
                   req.body.respond_to?(:source) ? req.body.source : req.body.instance_variable_get(:@body)
                 else
                   req.body
                 end

          HttpLog.call(
            method: req.verb,
            url: req.uri,
            request_body: body,
            request_headers: req.headers,
            response_code: @response.code,
            response_body: @response.body,
            response_headers: @response.headers,
            benchmark: bm,
            encoding: @response.headers['Content-Encoding'],
            content_type: @response.headers['Content-Type']
          )

          body.rewind if body.respond_to?(:rewind)
        end

        @response
      end
    end

    class Connection
      alias orig_initialize initialize unless method_defined?(:orig_initialize)

      def initialize(req, options)
        HttpLog.log_connection(req.uri.host, req.uri.port) if HttpLog.url_approved?(req.uri)
        orig_initialize(req, options)
      end
    end
  end
end
