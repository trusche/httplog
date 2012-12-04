if defined?(Patron)
  module Patron
    class Session
      alias_method :orig_request, :request
      def request(action_name, url, headers, options = {})
        HttpLog.log_request(action_name, url)
        HttpLog.log_headers(headers)
        HttpLog.log_data(options[:data]) if action_name == :post

        bm = Benchmark.realtime do
          @response = orig_request(action_name, url, headers, options)
        end

        HttpLog.log_compact(action_name, url, @response.status, bm)
        HttpLog.log_status(@response.status)
        HttpLog.log_benchmark(bm)
        HttpLog.log_body(@response.body)
      end
    end
  end
end
