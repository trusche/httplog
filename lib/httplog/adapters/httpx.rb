# frozen_string_literal: true

module HTTPX
  class Session
    private

    # callback executed when a response for a given request has been received.
    def on_response(request, response)
      if HttpLog.url_approved?(request.uri)
        HttpLog.call(
          method: request.verb,
          url: request.uri,
          request_body: request.body.to_s,
          request_headers: request.headers.to_hash,
          response_code: response.status,
          response_body: response.body.to_s,
          response_headers: response.headers.to_hash,
          # benchmark: bm,
          encoding: response.headers['content-encoding'],
          content_type: response.headers['content-type'],
          mask_body: HttpLog.masked_body_url?(request.uri)
        )
      end

      @responses[request] = response
    end
  end
end
