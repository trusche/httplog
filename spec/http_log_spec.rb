require 'spec_helper'

describe HttpLog do

  context "Misc" do
    
    it "should log at DEBUG by default" do
      Net::HTTP.get_response("localhost", "/", 3000)
      log.should include("DEBUG")
    end
    
    it "should log at other levels" do
      HttpLog.severity = Logger::Severity::INFO
      Net::HTTP.get_response("localhost", "/", 3000)
      log.should include("INFO")
    end
    
  end
  
  context "GET" do
    before(:each) do
      @url = URI.parse('http://localhost:3000/')
      @req = Net::HTTP::Get.new(@url.path)
      @res = Net::HTTP.start(@url.host, @url.port) {|http|
        http.request(@req)
      }
    end
  
    it "should log the connection" do
      log.should include("Connecting: #{@url.host}")
    end

    it "should log the request with method and path" do
      log.should include("Sending: GET #{@url.scheme}://#{@url.host}:#{@url.port}#{@url.path}")
    end
    
  end
  
  context "POST" do
    before(:each) do
      @url = URI.parse('http://www.example.com/todo.cgi')
      req = Net::HTTP::Post.new(@url.path)
      req.set_form_data({'from' => '2005-01-01', 'to' => '2005-03-31'}, ';')
      res = Net::HTTP.new(@url.host, @url.port).start {|http| http.request(req) }
    end

    it "should log the connection" do
      log.should include("Connecting: #{@url.host}")
    end

    it "should log the request with method and path" do
      log.should include("Sending: POST #{@url.scheme}://#{@url.host}:#{@url.port}#{@url.path}")
    end

    it "should log the request body" do
      log.should include("Body: from=2005-01-01;to=2005-03-31")
    end
  end
  
end