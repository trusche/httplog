# frozen_string_literal: true

if defined?(Excon)
  module Excon
    module HttpLogHelper
      def httplog_url(datum)
        @httplog_url ||= ["#{datum[:scheme]}://#{datum[:host]}:#{datum[:port]}#{datum[:path]}", datum[:query]].compact.join('?')
      end
    end

    class Socket
      include Excon::HttpLogHelper
      alias orig_connect connect
      def connect
        host = @data[:proxy] ? @data[:proxy][:host] : @data[:host]
        port = @data[:proxy] ? @data[:proxy][:port] : @data[:port]
        HttpLog.log_connection(host, port) if ::HttpLog.url_approved?(httplog_url(@data))
        orig_connect
      end
    end

    class Connection
      include Excon::HttpLogHelper
      attr_reader :bm

      alias orig_request request
      def request(params, &block)
        result = nil
        bm = Benchmark.realtime do
          result = orig_request(params, &block)
        end

        url = httplog_url(@data)
        return result unless HttpLog.url_approved?(url)

        headers = result[:headers] || {}

        HttpLog.call(
          method: params[:method],
          url: url,
          request_body: @data[:body],
          request_headers: @data[:headers] || {},
          response_code: result[:status],
          response_body: result[:body],
          response_headers: headers,
          benchmark: bm,
          encoding: headers['Content-Encoding'],
          content_type: headers['Content-Type'],
          mask_body: HttpLog.masked_body_url?(url)
        )
        result
      end
    end
  end
end
