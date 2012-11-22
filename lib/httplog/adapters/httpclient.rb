
if defined?(::HTTPClient)
  class HTTPClient
    private
    alias_method :orig_do_request, :do_request

    def do_request(method, uri, query, body, header, &block)
      HttpLog.log_request(method.to_s.upcase, uri)
      HttpLog.log_headers(header)
      HttpLog.log_data(body) if method == :post

      bm = Benchmark.realtime do
        @response  = orig_do_request(method, uri, query, body, header, &block)
      end

      HttpLog.log_compact(method.to_s.upcase, uri, @response.status, bm)
      HttpLog.log_status(@response.status)
      HttpLog.log_benchmark(bm)
      HttpLog.log_body(@response.body)

      @response
    end
  end
end
