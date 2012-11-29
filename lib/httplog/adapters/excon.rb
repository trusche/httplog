if defined?(Excon)
  module Excon
    class Socket
      alias_method :orig_connect, :connect
      def connect
        host = @proxy ? @proxy[:host] : @params[:host]
        port = @proxy ? @proxy[:port] : @params[:port]
        HttpLog.log_connection(host, port)
        orig_connect
      end

    end

    class Connection
      alias_method :orig_request_kernel, :request_kernel
      def request_kernel(params)
       url = "#{params[:scheme]}://#{params[:host]}:#{params[:port]}#{params[:path]}#{params[:query]}"
        HttpLog.log_request(params[:method], url)
        HttpLog.log_headers(params[:headers])
        HttpLog.log_data(params[:body]) if params[:method] == :post

        response = nil
        bm = Benchmark.realtime do
          response = orig_request_kernel(params)
        end

        HttpLog.log_compact(params[:method], url, response.status, bm)
        HttpLog.log_status(response.status)
        HttpLog.log_benchmark(bm)
        HttpLog.log_body(response.body)

        response
      end
    end
  end
end
