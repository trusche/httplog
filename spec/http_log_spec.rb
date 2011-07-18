require 'spec_helper'

describe HttpLog do

  before {
    @host = 'localhost'
    @port = 80
    @path = "/foo"
    @data = {'q' => 'ruby', 'max' => '50'}
  }
  
  def send_get_request
    Net::HTTP.get_response(@host, @path, @port)
  end
  
  def send_post_request
    res = Net::HTTP.post_form(URI.parse("http://#{@host}#{@path}"), @data)
  end

  context "with default config" do
  
    it "should log at DEBUG by default" do
      send_get_request
      log.should include("DEBUG")
    end
  
    it "should log the connection by default" do
      send_get_request
      log.should include("Connecting: #{@host}")
    end

    it "should log GET requests" do
      send_get_request
      log.should include("Sending: GET http://#{@host}:#{@port}#{@path}")
    end

    it "should not log data for GET requests" do
      send_get_request
      log.should_not include("Data:")
    end
    
    it "should log POST requests" do
      send_post_request
      log.should include("Sending: POST http://#{@host}:#{@port}#{@path}")
    end

    it "should log POST data" do
      send_post_request
      log.should include("Data: q=ruby&max=50")
    end
    
    it "should log data with http.post" do
      uri = URI.parse("http://sms.4rnd.com/mgf/service2.php")
      http = Net::HTTP.new(uri.host, uri.port)
#      http.use_ssl = uri.scheme == "https"
      resp = http.post(uri.path, "foo=bar")
      log.should include("Data: foo=bar")
    end
    
  
  end
  
  context "with custom config" do

    it "should log at other levels" do
      HttpLog.options[:severity] = Logger::Severity::INFO
      send_get_request
      log.should include("INFO")
    end

    it "should not log the request if disabled" do
      HttpLog.options[:log_request] = false
      send_get_request
      log.should_not include("Sending: GET")
    end

    it "should not log the connection if disabled" do
      HttpLog.options[:log_connect] = false
      send_get_request
      log.should_not include("Connecting: #{@host}")
    end

    it "should not log POST data if disabled" do
      HttpLog.options[:log_data] = false
      send_post_request
      log.should_not include("Data:")
    end
  
  end
  
end