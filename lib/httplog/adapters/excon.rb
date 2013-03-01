if defined?(Excon)
  module Excon
    class Socket
      alias_method :orig_connect, :connect
      def connect
        host = @data[:proxy] ? @data[:proxy][:host] : @data[:host]
        port = @data[:proxy] ? @data[:proxy][:port] : @data[:port]
        HttpLog.log_connection(host, port)
        orig_connect
      end

    end

    class Connection

      def _httplog_url(datum)
        "#{datum[:scheme]}://#{datum[:host]}:#{datum[:port]}#{datum[:path]}#{datum[:query]}"
      end

      alias_method :orig_request, :request
      def request(params, &block)
        datum = nil
        bm = Benchmark.realtime do
          datum = orig_request(params, &block)
        end
        HttpLog.log_compact(datum[:method], _httplog_url(datum), datum[:status], bm)
        HttpLog.log_benchmark(bm)
        datum
      end

      alias_method :orig_request_call, :request_call
      def request_call(datum)
        HttpLog.log_request(datum[:method], _httplog_url(datum))
        HttpLog.log_headers(datum[:headers])
        HttpLog.log_data(datum[:body]) if datum[:method] == :post
        orig_request_call(datum)
      end

      alias_method :orig_response, :response
      def response(datum={})
        bm = Benchmark.realtime do
          datum = orig_response(datum)
        end
        response = datum[:response]
        HttpLog.log_status(response[:status])
        HttpLog.log_body(response[:body])
        datum
      end
    end
  end
end
