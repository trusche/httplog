# frozen_string_literal: true

if defined?(Ethon)
  module Ethon
    class Easy
      attr_accessor :action_name

      module Http
        alias orig_http_request http_request
        def http_request(url, action_name, options = {})
          @http_log = options.merge(method: action_name, url: url) # remember this for compact logging
          orig_http_request(url, action_name, options)
        end
      end

      module Operations
        alias orig_perform perform
        def perform
          return orig_perform unless HttpLog.url_approved?(url)

          httplog_add_callback

          bm = Benchmark.realtime { orig_perform }

          url = @http_log[:url]
          url = "#{url}?#{@http_log[:params]}" if @http_log[:params]

          HttpLog.call(
            method: @http_log[:method],
            url: url,
            request_body: @http_log[:body],
            request_headers: @http_log[:headers],
            response_code: @return_code,
            response_body: @http_log[:response_body],
            response_headers: @http_log[:response_headers].map { |header| header.split(/:\s/) }.to_h,
            benchmark: bm,
            encoding: @http_log[:encoding],
            content_type: @http_log[:content_type],
            mask_body: HttpLog.masked_body_url?(@http_log[:url])
          )
          return_code
        end

        def httplog_add_callback
          # Hack to perform this callback before the cleanup
          @on_complete ||= []
          @on_complete.unshift -> (*) do
            # Not sure where the actual status code is stored - so let's
            # extract it from the response header.
            encoding = response_headers.scan(/Content-Encoding: (\S+)/i).flatten.first
            content_type = response_headers.scan(/Content-Type: (\S+(; charset=\S+)?)/i).flatten.first

            # Hard to believe that Ethon wouldn't parse out the headers into
            # an array; probably overlooked it. Anyway, let's do it ourselves:
            headers = response_headers.split(/\r?\n/).drop(1)

            @http_log.merge!(
              encoding: encoding,
              content_type: content_type,
              response_headers: headers,
              response_body: response_body
            )
          end
        end
      end
    end
  end
end
