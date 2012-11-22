
if defined?(::HTTPClient)
  class HTTPClient
    private
    alias_method :orig_do_get_block, :do_get_block
    
    def do_get_block(req, proxy, conn, &block)
      HttpLog.log_request(req.header.request_method, req.header.request_uri)
      HttpLog.log_headers(req.headers)
      HttpLog.log_data(req.body) if req.header.request_method == "POST"

      retryable_response = nil
      bm = Benchmark.realtime do
        begin
          orig_do_get_block(req, proxy, conn, &block)
        rescue RetryableResponse => e
          retryable_response = e
        end
      end
      
      res = conn.pop
      HttpLog.log_compact(req.header.request_method, req.header.request_uri, res.status_code, bm)
      HttpLog.log_status(res.status_code)
      HttpLog.log_benchmark(bm)
      HttpLog.log_body(res.body)
      conn.push(res)
      
      raise retryable_response if retryable_response != nil
    end
  end
end
