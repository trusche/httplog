require 'faraday'
class FaradayAdapter < HTTPBaseAdapter
  def send_get_request
    connection.get do |req|
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

  private

  def connection
    Faraday.new(url: "#{@protocol}://#{@host}:#{@port}") do |faraday|
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end
end
