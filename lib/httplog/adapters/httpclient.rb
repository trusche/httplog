# frozen_string_literal: true

if defined?(::HTTPClient)
  class HTTPClient
    private

    alias orig_do_get_block do_get_block

    def do_get_block(req, proxy, conn, &block)
      log_enabled = HttpLog.url_approved?(req.header.request_uri)

      if log_enabled
        HttpLog.log_request(req.header.request_method, req.header.request_uri)
        HttpLog.log_headers(req.headers)
        HttpLog.log_data(req.body)
      end

      retryable_response = nil
      bm = Benchmark.realtime do
        begin
          orig_do_get_block(req, proxy, conn, &block)
        rescue RetryableResponse => e
          retryable_response = e
        end
      end

      if log_enabled
        res = conn.pop
        headers = res.headers
        HttpLog.log_compact(req.header.request_method, req.header.request_uri, res.status_code, bm)
        HttpLog.log_json(
          method: req.header.request_method,
          url: req.header.request_uri,
          request_body: req.body,
          request_headers: req.headers,
          response_code: res.status_code,
          response_body: res.body,
          response_headers: headers,
          benchmark: bm
        )
        HttpLog.log_status(res.status_code)
        HttpLog.log_benchmark(bm)
        HttpLog.log_headers(headers)
        HttpLog.log_body(res.body, headers['Content-Encoding'], headers['Content-Type'])
        conn.push(res)
      end

      raise retryable_response unless retryable_response.nil?
    end

    class Session
      alias orig_create_socket create_socket

      # up to version 2.6, the method signature is `create_socket(site)`; after that,
      # it's `create_socket(hort, port)`
      if instance_method(:create_socket).arity == 1
        def create_socket(site)
          if HttpLog.url_approved?("#{site.host}:#{site.port}")
            HttpLog.log_connection(site.host, site.port)
          end
          orig_create_socket(site)
        end

      else
        def create_socket(host, port)
          if HttpLog.url_approved?("#{host}:#{port}")
            HttpLog.log_connection(host, port)
          end
          orig_create_socket(host, port)
        end
      end
    end
  end
end
