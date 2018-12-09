# frozen_string_literal: true

if defined?(Patron)
  module Patron
    class Session
      alias orig_request request
      def request(action_name, url, headers, options = {})
        bm = Benchmark.realtime do
          @response = orig_request(action_name, url, headers, options)
        end

        if HttpLog.url_approved?(url)
          HttpLog.call(
            method: action_name,
            url: url,
            request_body: options[:data],
            request_headers: headers,
            response_code: @response.status,
            response_body: @response.body,
            response_headers: @response.headers,
            benchmark: bm,
            encoding: @response.headers['Content-Encoding'],
            content_type: @response.headers['Content-Type']
          )
        end

        @response
      end
    end
  end
end
