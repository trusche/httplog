# frozen_string_literal: true

require 'patron'
class PatronAdapter < HTTPBaseAdapter
  def send_get_request
    session = Patron::Session.new
    session.get(parse_uri(true).to_s, @headers)
  end

  def send_head_request
    session = Patron::Session.new
    session.head(parse_uri.to_s, @headers)
  end

  def send_post_request
    session = Patron::Session.new
    session.post(parse_uri.to_s, @data, @headers)
  end

  def send_post_form_request
    session = Patron::Session.new
    session.post(parse_uri.to_s, @params, @headers)
  end

  def send_multipart_post_request
    data = @params.dup
    file = @params.delete('file')

    session = Patron::Session.new
    session.post_multipart(parse_uri.to_s, data, { file: file.path }, @headers)
  end

  def self.is_libcurl?
    true
  end
end
