require 'spec_helper'

# We're not using FakeWeb for testing, since that overrides some of the same Net::HTTP methods as
# httplog, and doesn't call the connect method at all. Instead, change the URL
# parameters to some suitable local or remote destination.
describe HttpLog do

  before {
    @host = 'localhost'
    @port = 3000
    @path = "/foo"
    @params = {'foo' => 'bar', 'bar' => 'foo'}
    @data = "foo=bar&bar=foo"
    @uri = URI.parse("http://#{@host}:#{@port}#{@path}")
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
  
    it "should log at DEBUG level" do
      send_get_request
      log.should include("DEBUG")
    end
  
    it "should log GET requests without data" do
      send_get_request
      log.should include("[httplog] Connecting: #{@host}")
      log.should include("[httplog] Sending: GET http://#{@host}:#{@port}#{@path}")
      log.should include("[httplog] Response:")
      log.should_not include("[httplog] Data:")
      log.should include("[httplog] Benchmark: ")
    end

    it "should log POST requests with data" do
      send_post_request
      log.should include("[httplog] Connecting: #{@host}")
      log.should include("[httplog] Sending: POST http://#{@host}:#{@port}#{@path}")
      log.should include("[httplog] Response:")
      log.should include("[httplog] Data: #{@data}")
      log.should include("[httplog] Benchmark: ")
    end

    it "should work with post_form" do
      send_post_form_request
      log.should include("[httplog] Connecting: #{@host}")
      log.should include("[httplog] Sending: POST http://#{@host}:#{@port}#{@path}")
      log.should include("[httplog] Response:")
      log.should include("[httplog] Data: #{@data}")
      log.should include("[httplog] Benchmark: ")
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
      log.should_not include("[httplog] Sending: GET")
    end

    it "should not log the connection if disabled" do
      HttpLog.options[:log_connect] = false
      send_get_request
      log.should_not include("[httplog] Connecting: #{@host}")
    end

    it "should not log POST data if disabled" do
      HttpLog.options[:log_data] = false
      send_post_request
      log.should_not include("[httplog] Data:")
    end
    
    it "should not log the response if disabled" do
      HttpLog.options[:log_response] = false
      send_post_request
      log.should_not include("[httplog] Reponse:")
    end

    it "should not log the benchmark if disabled" do
      HttpLog.options[:log_benchmark] = false
      send_post_request
      log.should_not include("[httplog] Benchmark:")
    end
  end

  context "with compact config" do
    it "should log a signle line with status and benchmark" do
      HttpLog.options[:compact_log] = true
      send_get_request
      log.should match /\[httplog\] GET http:\/\/#{@host}:#{@port}#{@path} completed with status code \d{3} in (\d|\.)*/

      log.should_not include("[httplog] Connecting: #{@host}")
      log.should_not include("[httplog] Response:")
      log.should_not include("[httplog] Data:")
      log.should_not include("[httplog] Benchmark: ")
    end
  end
  
end
