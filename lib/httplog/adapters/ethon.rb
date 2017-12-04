if defined?(Ethon)
  module Ethon
    class Easy

      attr_accessor :action_name

      module Http
        alias_method :orig_http_request, :http_request
        def http_request(url, action_name, options = {})
          @action_name = action_name # remember this for compact logging
          if HttpLog.url_approved?(url)
            HttpLog.log_request(action_name, url)
            HttpLog.log_headers(options[:headers])
            HttpLog.log_data(options[:body], options[:headers]['Content-Type']) #if action_name == :post
          end

          orig_http_request(url, action_name, options)
        end
      end

      module Operations
        alias_method :orig_perform, :perform
        def perform
          return orig_perform unless HttpLog.url_approved?(url)

          response_code = nil
          bm = Benchmark.realtime do
            reponse_code = orig_perform
          end

          # Not sure where the actual status code is stored - so let's
          # extract it from the response header.
          status   = response_headers.scan(/HTTP\/... (\d{3})/).flatten.first
          encoding = response_headers.scan(/Content-Encoding: (\S+)/).flatten.first
          content_type = response_headers.scan(/Content-Type: (\S+(; charset=\S+)?)/).flatten.first

          # Hard to believe that Ethon wouldn't parse out the headers into
          # an array; probably overlooked it. Anyway, let's do it ourselves:
          headers = response_headers.split(/\r?\n/)[1..-1]

          HttpLog.log_compact(@action_name, @url, @return_code, bm)
          HttpLog.log_status(status)
          HttpLog.log_benchmark(bm)
          HttpLog.log_headers(headers)
          HttpLog.log_body(response_body, encoding, content_type)
          return_code
        end
      end
    end
  end
end
