# frozen_string_literal: true

if defined?(::HTTPClient)
  class HTTPClient
    private

    alias orig_do_get_block do_get_block

    def do_get_block(req, proxy, conn, &block)
      retryable_response = nil
      bm = Benchmark.realtime do
        begin
          orig_do_get_block(req, proxy, conn, &block)
        rescue RetryableResponse => e
          retryable_response = e
        end
      end

      if HttpLog.url_approved?(req.header.request_uri)
        res = conn.pop

        HttpLog.call(
          method: req.header.request_method,
          url: req.header.request_uri,
          request_body: req.body,
          request_headers: req.headers,
          response_code: res.status_code,
          response_body: res.body,
          response_headers: res.headers,
          benchmark: bm,
          encoding: res.headers['Content-Encoding'],
          content_type: res.headers['Content-Type']
        )
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
