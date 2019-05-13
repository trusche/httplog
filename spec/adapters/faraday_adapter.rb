# frozen_string_literal: true

require 'faraday'
class FaradayAdapter < HTTPBaseAdapter
  def send_get_request
    connection.get do |req|
      req.url parse_uri(true).to_s
      req.headers = @headers
    end
  end

  def send_head_request
    connection.head do |req|
      req.url parse_uri.to_s
      req.headers = @headers
    end
  end

  def send_post_request
    connection.post do |req|
      req.url parse_uri.to_s
      req.headers = @headers
      req.body = @data
    end
  end

  def send_post_form_request
    connection.post do |req|
      req.url parse_uri.to_s
      req.headers = @headers
      req.body = @params
    end
  end

  def send_multipart_post_request
    file_upload = Faraday::UploadIO.new(@params['file'], 'text/plain')

    connection.post do |req|
      req.url parse_uri.to_s
      req.headers = @headers
      req.body = @params.merge('file' => file_upload)
    end
  end

  def logs_form_data?
    false
  end

  private

  def connection
    Faraday.new(url: "#{@protocol}://#{@host}:#{@port}") do |faraday|
      faraday.request :multipart
      faraday.request :url_encoded

      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end
  end
end
