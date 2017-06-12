# encoding: UTF-8

require 'spec_helper'

describe HttpLog do

  let(:host) { 'localhost' }
  let(:port) { 9292 }
  let(:path) { "/index.html" }
  let(:headers) { { "accept" => "*/*", "foo" => "bar" } }
  let(:data) { "foo=bar&bar=foo" }
  let(:params) { {'foo' => 'bar:form-data', 'bar' => 'foo'} }

  ADAPTERS = [
    NetHTTPAdapter,
    OpenUriAdapter,
    HTTPClientAdapter,
    HTTPartyAdapter,
    FaradayAdapter,
    ExconAdapter,
    EthonAdapter,
    # FIXME: typheous does weird things to reponse headers using ethon as the default adapter, 
    # even though ethon stand-alone works just fine. Not worth supporting since Typhoeus has its
    # own logging facility.
    #
    # TyphoeusAdapter, 
    PatronAdapter,
    HTTPAdapter
  ]

  ADAPTERS.each do |adapter_class|
    context adapter_class, :adapter => adapter_class.to_s do
      let(:adapter) { adapter_class.new(host, port, path, headers, data, params) }

      context "with default configuration" do
        connection_test_method = adapter_class.is_libcurl? ? :to_not : :to

        if adapter_class.method_defined? :send_get_request
          it "should log GET requests" do
            res = adapter.send_get_request

            expect(log).send(connection_test_method, include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}"))

            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: GET http://#{host}:#{port}#{path}")
            expect(log).to include(HttpLog::LOG_PREFIX + "Data:")
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Header:")
            expect(log).to include(HttpLog::LOG_PREFIX + "Status: 200")
            expect(log).to include(HttpLog::LOG_PREFIX + "Benchmark: ")
            expect(log).to include(HttpLog::LOG_PREFIX + "Response:#{adapter.expected_response_body}")
            expect(log.colorized?).to be_falsey

            expect(res).to be_a adapter.response if adapter.respond_to? :response
          end

          context "with gzipped response body" do
            let(:path) { '/index.html.gz' }
            let(:data) { nil }

            it "decompresses gzipped response body" do
              adapter.send_get_request
              expect(log).to include(HttpLog::LOG_PREFIX + "Response:#{adapter.expected_response_body}")
            end

            if adapter_class.method_defined? :send_head_request
              it "doesn't try to decompress body for HEAD requests" do
                adapter.send_head_request
                expect(log).to include(HttpLog::LOG_PREFIX + "Response:")
              end
            end
          end

          context "with UTF-8 response body" do
            let(:path) { '/utf8.html' }
            let(:data) { nil }

            it "works" do
              adapter.send_get_request
              expect(log).to include(HttpLog::LOG_PREFIX + "Response:#{adapter.expected_response_body}")
              if adapter.logs_data?
                expect(log).to include("    <title>Блог Яндекса</title>")
              end
            end
          end

          context "with binary response body" do
            let(:path) { '/test.bin' }
            let(:data) { nil }

            it "doesn't log response" do
              adapter.send_get_request
              expect(log).to include(HttpLog::LOG_PREFIX + "Response: (not showing binary data)")
            end
          end
        end

        if adapter_class.method_defined? :send_post_request
          it "logs POST requests" do
            res = adapter.send_post_request

            expect(log).send(connection_test_method, include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}"))

            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: POST http://#{host}:#{port}#{path}")
            expect(log).to include(HttpLog::LOG_PREFIX + "Data: foo=bar&bar=foo")
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Header:")
            expect(log).to include(HttpLog::LOG_PREFIX + "Status: 200")
            expect(log).to include(HttpLog::LOG_PREFIX + "Benchmark: ")
            expect(log).to include(HttpLog::LOG_PREFIX + "Response:#{adapter.expected_response_body}")
            expect(log.colorized?).to be_falsey

            expect(res).to be_a adapter.response if adapter.respond_to? :response
          end

          context "with non-UTF request data" do
            let(:data) { "a UTF-8 striñg with an 8BIT-ASCII character: \xC3".freeze }
            it "does not raise and error" do
              expect {adapter.send_post_request }.to_not raise_error
              expect(log).to include(HttpLog::LOG_PREFIX + "Response:")
            end
          end

          context "with URI encoded non-UTF data" do
            let(:data) { "a UTF-8 striñg with a URI encoded 8BIT-ASCII character: %c3" }
            it "does not raise and error" do
              expect { adapter.send_post_request }.to_not raise_error
              expect(log).to include(HttpLog::LOG_PREFIX + "Response:")
            end
          end
        end
      end

      context "with custom configuration" do
        context "GET requests" do

          it "should log at other levels" do
            HttpLog.configure { |c| c.severity = Logger::Severity::INFO }
            adapter.send_get_request
            expect(log).to include("INFO")
          end

          it "should log headers if enabled" do
            HttpLog.configure { |c| c.log_headers = true }
            adapter.send_get_request
            expect(log.downcase).to include(HttpLog::LOG_PREFIX + "Header: accept: */*".downcase)
          end

          it "should not log headers if disabled" do
            HttpLog.configure { |c| c.log_headers = false }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Header:")
          end

          it "should log the request if url does not match blacklist pattern" do
            HttpLog.configure { |c| c.url_blacklist_pattern = /example.com/ }
            adapter.send_get_request
            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should log the request if url matches whitelist pattern and not the blacklist pattern" do
            HttpLog.configure { |c| c.url_blacklist_pattern = /example.com/ }
            HttpLog.configure { |c| c.url_whitelist_pattern = /#{host}:#{port}/ }
            adapter.send_get_request
            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if url matches blacklist pattern" do
            HttpLog.configure { |c| c.url_blacklist_pattern = /#{host}:#{port}/ }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if url does not match whitelist pattern" do
            HttpLog.configure { |c| c.url_whitelist_pattern = /example.com/ }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if url matches blacklist pattern and the whitelist pattern" do
            HttpLog.configure { |c| c.url_blacklist_pattern = /#{host}:#{port}/ }
            HttpLog.configure { |c| c.url_whitelist_pattern = /#{host}:#{port}/ }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if disabled" do
            HttpLog.configure { |c| c.log_request = false }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the connection if disabled" do
            HttpLog.configure { |c| c.log_connect = false }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}")
          end

          it "should not log data if disabled" do
            HttpLog.configure { |c| c.log_data = false }
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
          end

          it "should colorized output" do
            HttpLog.configure { |c| c.color = :red }
            adapter.send_get_request
            expect(log.colorized?).to be_truthy
          end

          it "should log with custom string prefix" do
            HttpLog.configure { |c| c.prefix = '[my logger]' }
            adapter.send_get_request
            expect(log).to include("[my logger]")
            expect(log).to_not include(HttpLog::LOG_PREFIX)
          end

          it "should log with custom lambda prefix" do
            HttpLog.configure { |c| c.prefix = -> { '[custom prefix]' } }
            adapter.send_get_request
            expect(log).to include("[custom prefix]")
            expect(log).to_not include(HttpLog::LOG_PREFIX)
          end
        end

        context "POST requests" do
          if adapter_class.method_defined? :send_post_request
            it "should not log data if disabled" do
              HttpLog.configure { |c| c.log_data = false }
              adapter.send_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
            end

            it "should not log the response if disabled" do
              HttpLog.configure { |c| c.log_response = false }
              adapter.send_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Reponse:")
            end

            it "should prefix all response lines" do
              HttpLog.configure { |c| c.prefix_response_lines = true }

              adapter.send_post_request
              expect(log).to include(HttpLog::LOG_PREFIX + "Response:")
              expect(log).to include(HttpLog::LOG_PREFIX + "<html>")
            end

            it "should prefix all response lines with line numbers" do
              HttpLog.configure { |c| c.prefix_response_lines = true }
              HttpLog.configure { |c| c.prefix_line_numbers = true }

              adapter.send_post_request
              expect(log).to include(HttpLog::LOG_PREFIX + "Response:")
              expect(log).to include(HttpLog::LOG_PREFIX + "1: <html>")
            end

            it "should not log the benchmark if disabled" do
              HttpLog.configure { |c| c.log_benchmark = false }
              adapter.send_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark:")
            end

            it "should colorized output" do
              HttpLog.configure { |c| c.color = :red }
              adapter.send_post_request
              expect(log.colorized?).to be_truthy
            end
          end
        end

        context "POST form data requests" do
          if adapter_class.method_defined? :send_post_form_request
            it "should not log data if disabled" do
              HttpLog.configure { |c| c.log_data = false }
              adapter.send_post_form_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
            end

            it "should not log the response if disabled" do
              HttpLog.configure { |c| c.log_response = false }
              adapter.send_post_form_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Reponse:")
            end

            it "should not log the benchmark if disabled" do
              HttpLog.configure { |c| c.log_benchmark = false }
              adapter.send_post_form_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark:")
            end
          end
        end

        context "POST multi-part requests (file upload)" do
          let(:upload) { Tempfile.new('http-log') }
          let(:params) { {'foo' => 'bar', 'file' => upload} }

          if adapter_class.method_defined? :send_multipart_post_request
            it "should not log data if disabled" do
              HttpLog.configure { |c| c.log_data = false }
              adapter.send_multipart_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
            end

            it "should not log the response if disabled" do
              HttpLog.configure { |c| c.log_response = false }
              adapter.send_multipart_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Reponse:")
            end

            it "should not log the benchmark if disabled" do
              HttpLog.configure { |c| c.log_benchmark = false }
              adapter.send_multipart_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark:")
            end
          end
        end
      end

      context "with compact config" do
        before(:each) { HttpLog.configure { |c| c.compact_log = true } }

        it "should log a single line with status and benchmark" do
          adapter.send_get_request
          expect(log).to match /\[httplog\] GET http:\/\/#{host}:#{port}#{path}(\?.*)? completed with status code \d{3} in (\d|\.)+/
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}")
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Response:")
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark: ")
        end
      end

=begin # NOTE: dropping this in v0.99.0 to support ruby 2.4.0. log4r has been stale for years.
      context "with log4r" do

        before(:each) do 
          require 'log4r'
          require 'log4r/yamlconfigurator'
          require 'log4r/outputter/datefileoutputter'
          log4r_config= YAML.load_file(File.join(File.dirname(__FILE__),"support/log4r.yml"))
          Log4r::YamlConfigurator.decode_yaml( log4r_config['log4r_config'] )
          HttpLog.configure{ |c| c.logger = Log4r::Logger['test'] }
        end

        it "works" do
          expect { adapter.send_get_request }.to_not raise_error
        end
      end
=end
    end
  end

end
