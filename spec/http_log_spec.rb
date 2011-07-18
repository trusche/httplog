require 'spec_helper'

describe HttpLog do

  before {
    @host = 'localhost'
    @port = 80
    @path = "/foo"
    @params = {'foo' => 'bar', 'bar' => 'foo'}
    @data = "foo=bar&bar=foo"
    @uri = URI.parse("http://#{@host}#{@path}")
  }
  
  def send_get_request
    Net::HTTP.get_response(@host, @path, @port)
  end
  
  def send_post_request
    http = Net::HTTP.new(@uri.host, @uri.port)
    resp = http.post(@uri.path, @data)
  end

  def send_post_form_request
    res = Net::HTTP.post_form(@uri, @params)
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
      log.should include("Data: #{@data}")
    end
    
    it "should log only once" do
      send_post_request
      log.lines.count.should == 3
    end

    it "should work with post_form" do
      send_post_form_request
      log.should include("Sending: POST http://#{@host}:#{@port}#{@path}")
      log.should include("Data: #{@data}")
      log.lines.count.should == 3
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