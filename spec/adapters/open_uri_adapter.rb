class OpenUriAdapter < HTTPBaseAdapter
  def send_get_request
    open(parse_uri)
  end
end
