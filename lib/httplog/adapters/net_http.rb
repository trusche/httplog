# frozen_string_literal: true

module Net
  class HTTP
    alias orig_request request unless method_defined?(:orig_request)
    alias orig_connect connect unless method_defined?(:orig_connect)

    def request(req, body = nil, &block)
      url = req.uri.to_s

      log_enabled = HttpLog.url_approved?(url)

      if log_enabled && started?
        HttpLog.log_request(req.method, url)
        HttpLog.log_headers(req.each_header.collect)
        # A bit convoluted becase post_form uses form_data= to assign the data, so
        # in that case req.body will be empty.
        HttpLog.log_data(req.body.nil? || req.body.empty? ? body : req.body) # if req.method == 'POST'
      end

      bm = Benchmark.realtime do
        @response = orig_request(req, body, &block)
      end

      if log_enabled && started?
        HttpLog.log_compact(req.method, url, @response.code, bm)
        HttpLog.log_status(@response.code)
        HttpLog.log_benchmark(bm)
        HttpLog.log_headers(@response.each_header.collect)
        HttpLog.log_body(@response.body, @response['Content-Encoding'], @response['Content-Type'])
      end

      @response
    end

    def connect
      HttpLog.log_connection(@address, @port) if !started? && HttpLog.url_approved?("#{@address}:#{@port}")

      orig_connect
    end
  end
end
