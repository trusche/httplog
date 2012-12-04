require "patron"
class PatronAdapter < HTTPBaseAdapter
  def send_get_request
    session = Patron::Session.new
    session.get(parse_uri.to_s, @headers)
  end

  def send_post_request
    session = Patron::Session.new
    session.post(parse_uri.to_s, @data, @headers)
  end
end
