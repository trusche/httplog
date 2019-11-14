class GelfMock < Logger
  def log(severity, message = nil, progname = nil)
    message ||= {}
    if message.is_a?(Hash)
      message[:short_message] = message[:short_message].to_s

      message = message.each_with_object({}) do |(key, value), obj|
        key_s = key.to_s

        obj[key_s] = value
      end.to_json
    end
    super(severity, message, progname)
  end
end
