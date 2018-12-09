# frozen_string_literal: true

if defined?(Excon)
  module Excon
    module HttpLogHelper
      def _httplog_url(datum)
        @httplog_url ||= "#{datum[:scheme]}://#{datum[:host]}:#{datum[:port]}#{datum[:path]}#{datum[:query]}"
      end
    end

    class Socket
      include Excon::HttpLogHelper
      alias orig_connect connect
      def connect
        host = @data[:proxy] ? @data[:proxy][:host] : @data[:host]
        port = @data[:proxy] ? @data[:proxy][:port] : @data[:port]
        HttpLog.log_connection(host, port) if ::HttpLog.url_approved?(_httplog_url(@data))
        orig_connect
      end
    end

    class Connection
      include Excon::HttpLogHelper
      alias orig_request request
      def request(params, &block)
        result = nil
        bm = Benchmark.realtime do
          result = orig_request(params, &block)
        end

        datum = @data.merge(params)
        datum[:headers] = @data[:headers].merge(datum[:headers] || {})
        url = _httplog_url(datum)

        # if HttpLog.url_approved?(url)
        #   @http_log[:method] = datum[:method]
        #   @http_log[:response_code] = datum[:status] || result.status
        #   @http_log[:benchmark] = bm
        # end
        result
      end

      alias orig_response response
      def response(datum = {})
        return orig_response(datum) unless HttpLog.url_approved?(_httplog_url(datum))

        bm = Benchmark.realtime do
          datum = orig_response(datum)
        end # FIXME: benchmark should start before REQUEST!

        response = datum[:response]
        headers  = response[:headers] || {}

        HttpLog.call(
          method: datum[:method],
          url: _httplog_url(datum),
          request_body: datum[:body],
          request_headers: datum[:headers],
          response_code: response[:status],
          response_body: response[:body],
          response_headers: response[:headers],
          benchmark: bm,
          encoding: headers['Content-Encoding'],
          content_type: headers['Content-Type']
        )

        datum
      end
    end
  end
end
