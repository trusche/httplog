if defined?(::HTTP::Client) and defined?(::HTTP::Connection)
  module ::HTTP
    class Client
      alias_method(:orig_make_request, :make_request) unless method_defined?(:orig_make_request)

      def make_request(req, options)

        log_enabled = HttpLog.url_approved?(req.uri)

        if log_enabled
          HttpLog.log_request(req.verb, req.uri)
          HttpLog.log_headers(req.headers.to_h)
          HttpLog.log_data(req.body) if req.verb == :post
        end

        bm = Benchmark.realtime do
          @response = orig_make_request(req, options)
        end

        if log_enabled
          HttpLog.log_compact(req.verb, req.uri, @response.code, bm)
          HttpLog.log_status(@response.code)
          HttpLog.log_benchmark(bm)
          HttpLog.log_headers(@response.headers.to_h)
          HttpLog.log_body(@response.body, @response.headers["Content-Encoding"])
        end

        @response
      end

    end

    class Connection
      alias_method(:orig_initialize, :initialize) unless method_defined?(:orig_initialize)

      def initialize(req, options)

        HttpLog.log_connection(req.uri.host, req.uri.port) if HttpLog.url_approved?(req.uri)

        orig_initialize(req, options)
      end
    end
  end
end
