# frozen_string_literal: true

if defined?(::HTTPClient)
  module HttpLog
    module HTTPClient
      private

      def do_get_block(req, proxy, conn, &block)
        retryable_response = nil
        bm = Benchmark.realtime do
          begin
            super(req, proxy, conn, &block)
          rescue RetryableResponse => e
            retryable_response = e
          end
        end

        request_uri = req.header.request_uri
        if HttpLog.url_approved?(request_uri)
          res = conn.pop
          headers = res.headers.transform_keys(&:downcase)

          HttpLog.call(
            method: req.header.request_method,
            url: request_uri,
            request_body: req.body,
            request_headers: req.headers,
            response_code: res.status_code,
            response_body: res.body,
            response_headers: headers,
            benchmark: bm,
            encoding: headers['content-encoding'],
            content_type: headers['content-type'],
            mask_body: HttpLog.masked_body_url?(request_uri)
          )
          conn.push(res)
        end

        raise retryable_response unless retryable_response.nil?
      end

      module SessionOld
        # up to version 2.6, the method signature is `create_socket(site)`; after that,
        # it's `create_socket(host, port)`
        def create_socket(site)
          if HttpLog.url_approved?("#{site.host}:#{site.port}")
            HttpLog.log_connection(site.host, site.port)
          end

          super(site)
        end
      end

      module SessionLatest
        def create_socket(host, port)
          if HttpLog.url_approved?("#{host}:#{port}")
            HttpLog.log_connection(host, port)
          end

          super(host, port)
        end
      end
    end
  end

  HttpLog::Utils::MonkeyPatcher.register_patch(:httpclient) do
    ::HTTPClient.prepend(HttpLog::HTTPClient)
    ::HTTPClient::Session.prepend(HttpLog::HTTPClient::SessionLatest)
  end

  HttpLog::Utils::MonkeyPatcher.register_patch(:httpclient_old) do
    ::HTTPClient.prepend(HttpLog::HTTPClient)
    ::HTTPClient::Session.prepend(HttpLog::HTTPClient::SessionOld)
  end
end
