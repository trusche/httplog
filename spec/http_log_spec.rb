# We're not using FakeWeb for testing, since that overrides some of the same Net::HTTP methods as
# httplog, and doesn't call the connect method at all. Instead, change the URL
# parameters to some suitable local or remote destination.
require 'spec_helper'
require 'adapters/httpclient_adapter'
require 'adapters/net_http_adapter'
require 'adapters/open_uri_adapter'
require 'adapters/httparty_adapter'

describe HttpLog do

  before {
    @host = 'localhost'
    @port = 9292
    @path = "/index.html"
    @params = {'foo' => 'bar', 'bar' => 'foo'}
    @data = "foo=bar&bar=foo"
    @uri = URI.parse("http://#{@host}:#{@port}#{@path}")
  }

  context "Net::HTTP" do
    let(:adapter) { NetHTTPAdapter.new(@host, @port, @path) }

    context "with default config" do

      it "should log at DEBUG level" do
        adapter.send_get_request
        log.should include("DEBUG")
      end

      it "should log GET requests without data" do
        adapter.send_get_request
        log.should include("[httplog] Connecting: #{@host}:#{@port}")
        log.should include("[httplog] Sending: GET http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Response:")
        log.should include("<html>")
        log.should include("[httplog] Benchmark: ")
        log.should_not include("[httplog] Data:")
        log.should_not include("[httplog] Header:")
      end

      it "should log POST requests with data" do
        adapter.send_post_request(@data)
        log.should include("[httplog] Connecting: #{@host}:#{@port}")
        log.should include("[httplog] Sending: POST http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Response:")
        log.should include("[httplog] Data: #{@data}")
        log.should include("[httplog] Benchmark: ")
      end

      it "should work with post_form" do
        adapter.send_post_form_request(@params)
        log.should include("[httplog] Connecting: #{@host}:#{@port}")
        log.should include("[httplog] Sending: POST http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Response:")
        log.should include("[httplog] Data: #{@data}")
        log.should include("[httplog] Benchmark: ")
      end
    end

    context "with custom config" do
      it "should log at other levels" do
        HttpLog.options[:severity] = Logger::Severity::INFO
        adapter.send_get_request
        log.should include("INFO")
      end

      it "should log headers if enabled" do
        HttpLog.options[:log_headers] = true
        adapter.send_get_request
        log.should include("[httplog] Header: accept: */*")
        log.should include("[httplog] Header: user-agent: Ruby")
      end


      it "should not log the request if disabled" do
        HttpLog.options[:log_request] = false
        adapter.send_get_request
        log.should_not include("[httplog] Sending: GET")
      end

      it "should not log the connection if disabled" do
        HttpLog.options[:log_connect] = false
        adapter.send_get_request
        log.should_not include("[httplog] Connecting: #{@host}:#{@port}")
      end

      it "should not log POST data if disabled" do
        HttpLog.options[:log_data] = false
        adapter.send_post_request(@data)
        log.should_not include("[httplog] Data:")
      end

      it "should not log the response if disabled" do
        HttpLog.options[:log_response] = false
        adapter.send_post_request(@data)
        log.should_not include("[httplog] Reponse:")
      end

      it "should not log the benchmark if disabled" do
        HttpLog.options[:log_benchmark] = false
        adapter.send_post_request(@data)
        log.should_not include("[httplog] Benchmark:")
      end
    end

    context "with compact config" do
      it "should log a single line with status and benchmark" do
        HttpLog.options[:compact_log] = true
        adapter.send_get_request

        log.should match /\[httplog\] GET http:\/\/#{@host}:#{@port}#{@path} completed with status code \d{3} in (\d|\.)*/
        log.should_not include("[httplog] Connecting: #{@host}:#{@port}")
        log.should_not include("[httplog] Response:")
        log.should_not include("[httplog] Data:")
        log.should_not include("[httplog] Benchmark: ")
      end
    end
  end

  context "OpenURI" do
    let(:adapter) { OpenUriAdapter.new(@host, @port, @path) }

    context "with default config" do
      it "should log GET requests without data and response body" do
        res = adapter.send_get_request
        log.should include("[httplog] Connecting: #{@host}:#{@port}")
        log.should include("[httplog] Sending: GET http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Response: (not available yet)")
        log.should_not include("<html>")
        log.should include("[httplog] Benchmark: ")
      end
    end
  end

  context "HTTPClient" do
    let(:adapter) { HTTPClientAdapter.new(@host, @port, @path) }

    context "with all options" do
      before do
        HttpLog.options[:log_headers] = true
      end

      it "should log GET requests" do
        res = adapter.send_get_request
        res.should be_a HTTP::Message
        log.should include("[httplog] Connecting: #{@host}:#{@port}")
        log.should include("[httplog] Sending: GET http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Header: accept: */*")
        log.should include("[httplog] Header: foo: bar")
        log.should include("[httplog] Response:")
        log.should include("<html>")
        log.should include("[httplog] Benchmark: ")
        log.should include("[httplog] Header:")
      end

      it "should log POST requests" do
        res = adapter.send_post_request(@data)
        res.should be_a HTTP::Message
        log.should include("[httplog] Sending: POST http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Response:")
        log.should include("[httplog] Data: #{@data}")
        log.should include("[httplog] Benchmark: ")
      end
    end
  end

  context "HTTParty" do
    let(:adapter) { HTTPartyAdapter.new(@host, @port, @path) }

    context "with all options" do
      before do
        HttpLog.options[:log_headers] = true
      end

      it "should log GET requests" do
        res = adapter.send_get_request
        log.should include("[httplog] Connecting: #{@host}:#{@port}")
        log.should include("[httplog] Sending: GET http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Header: accept: */*")
        log.should include("[httplog] Header: foo: bar")
        log.should include("[httplog] Response:")
        log.should include("<html>")
        log.should include("[httplog] Benchmark: ")
        log.should include("[httplog] Header:")
      end

      it "should log POST requests" do
        res = adapter.send_post_request(@data)
        log.should include("[httplog] Sending: POST http://#{@host}:#{@port}#{@path}")
        log.should include("[httplog] Response:")
        log.should include("[httplog] Data: #{@data}")
        log.should include("[httplog] Benchmark: ")
      end
    end
  end
end
