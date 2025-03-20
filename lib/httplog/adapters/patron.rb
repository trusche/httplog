# frozen_string_literal: true

if defined?(::Patron::Session)
  module HttpLog
    module Patron
      module Session
        def request(action_name, url, headers, options = {})
          bm = Benchmark.realtime do
            @response = super(action_name, url, headers, options)
          end

          if HttpLog.url_approved?(url)
            normalized_headers = @response.headers.transform_keys(&:downcase)

            HttpLog.call(
              method: action_name,
              url: url,
              request_body: options[:data],
              request_headers: headers,
              response_code: @response.status,
              response_body: @response.body,
              response_headers: normalized_headers,
              benchmark: bm,
              encoding: normalized_headers['content-encoding'],
              content_type: normalized_headers['content-type'],
              mask_body: HttpLog.masked_body_url?(url)
            )
          end

          @response
        end
      end
    end
  end

  HttpLog::Utils::MonkeyPatcher.register_patch(:patron, HttpLog::Patron::Session, Patron::Session)
end
