# encoding: UTF-8

require 'spec_helper'

describe HttpLog do

  let(:host) { 'localhost' }
  let(:port) { 9292 }
  let(:path) { "/index.html" }
  let(:headers) { { "accept" => "*/*", "foo" => "bar" } }
  let(:data) { "foo=bar%3Azee&bar=foo" }
  let(:params) { {'foo' => 'bar:form-data', 'bar' => 'foo'} }

  ADAPTERS = [
    NetHTTPAdapter,
    OpenUriAdapter,
    HTTPClientAdapter,
    HTTPartyAdapter,
    FaradayAdapter,
    ExconAdapter,
    EthonAdapter,
    TyphoeusAdapter,
    PatronAdapter,
    HTTPAdapter
  ]

  ADAPTERS.each do |adapter_class|
    context adapter_class, :adapter => adapter_class.to_s do
      let(:adapter) { adapter_class.new(host, port, path, headers, data, params) }

      context "with default options" do
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
        end

        if adapter_class.method_defined? :send_post_request
          it "should log POST requests" do
            res = adapter.send_post_request

            expect(log).send(connection_test_method, include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}"))

            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: POST http://#{host}:#{port}#{path}")
            expect(log).to include(HttpLog::LOG_PREFIX + "Data: foo=bar:zee&bar=foo")
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Header:")
            expect(log).to include(HttpLog::LOG_PREFIX + "Status: 200")
            expect(log).to include(HttpLog::LOG_PREFIX + "Benchmark: ")
            expect(log).to include(HttpLog::LOG_PREFIX + "Response:#{adapter.expected_response_body}")
            expect(log.colorized?).to be_falsey

            expect(res).to be_a adapter.response if adapter.respond_to? :response
          end

          context "with binary data" do
            let(:data) { "a UTF-8 striñg with a URI encoded invalid codepoint %c3" }
            let(:unescaped_data) { "a UTF-8 striñg with a URI encoded invalid codepoint \xC3" }

            it "should log POST data converted to UTF-8" do
              adapter.send_post_request

              expect(log.force_encoding(Encoding::ASCII_8BIT)).to include(unescaped_data.force_encoding(Encoding::ASCII_8BIT))
            end
          end
        end
      end

      context "with custom config" do
        context "GET requests" do
          it "should log at other levels" do
            HttpLog.options[:severity] = Logger::Severity::INFO
            adapter.send_get_request
            expect(log).to include("INFO")
          end

          it "should log headers if enabled" do
            HttpLog.options[:log_headers] = true
            adapter.send_get_request
            expect(log.downcase).to include(HttpLog::LOG_PREFIX + "Header: accept: */*".downcase)
          end

          it "should not log headers if disabled" do
            HttpLog.options[:log_headers] = false
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Header:")
          end

          it "should log the request if url does not match blacklist pattern" do
            HttpLog.options[:url_blacklist_pattern] = /example.com/
            adapter.send_get_request
            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should log the request if url matches whitelist pattern and not the blacklist pattern" do
            HttpLog.options[:url_blacklist_pattern] = /example.com/
            HttpLog.options[:url_whitelist_pattern] = /#{host}:#{port}/
            adapter.send_get_request
            expect(log).to include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if url matches blacklist pattern" do
            HttpLog.options[:url_blacklist_pattern] = /#{host}:#{port}/
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if url does not match whitelist pattern" do
            HttpLog.options[:url_whitelist_pattern] = /example.com/
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if url matches blacklist pattern and the whitelist pattern" do
            HttpLog.options[:url_blacklist_pattern] = /#{host}:#{port}/
            HttpLog.options[:url_whitelist_pattern] = /#{host}:#{port}/
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the request if disabled" do
            HttpLog.options[:log_request] = false
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Sending: GET")
          end

          it "should not log the connection if disabled" do
            HttpLog.options[:log_connect] = false
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}")
          end

          it "should not log data if disabled" do
            HttpLog.options[:log_data] = false
            adapter.send_get_request
            expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
          end

          it "should colorized output" do
            HttpLog.options[:color] = :red
            adapter.send_get_request
            expect(log.colorized?).to be_truthy
          end
        end

        context "POST requests" do
          if adapter_class.method_defined? :send_post_request
            it "should not log data if disabled" do
              HttpLog.options[:log_data] = false
              adapter.send_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
            end

            it "should not log the response if disabled" do
              HttpLog.options[:log_response] = false
              adapter.send_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Reponse:")
            end

            it "should not log the benchmark if disabled" do
              HttpLog.options[:log_benchmark] = false
              adapter.send_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark:")
            end

            it "should colorized output" do
              HttpLog.options[:color] = :red
              adapter.send_post_request
              expect(log.colorized?).to be_truthy
            end
          end
        end

        context "POST form data requests" do
          if adapter_class.method_defined? :send_post_form_request
            it "should not log data if disabled" do
              HttpLog.options[:log_data] = false
              adapter.send_post_form_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
            end

            it "should not log the response if disabled" do
              HttpLog.options[:log_response] = false
              adapter.send_post_form_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Reponse:")
            end

            it "should not log the benchmark if disabled" do
              HttpLog.options[:log_benchmark] = false
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
              HttpLog.options[:log_data] = false
              adapter.send_multipart_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
            end

            it "should not log the response if disabled" do
              HttpLog.options[:log_response] = false
              adapter.send_multipart_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Reponse:")
            end

            it "should not log the benchmark if disabled" do
              HttpLog.options[:log_benchmark] = false
              adapter.send_multipart_post_request
              expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark:")
            end
          end
        end
      end

      context "with compact config" do
        it "should log a single line with status and benchmark" do
          HttpLog.options[:compact_log] = true
          adapter.send_get_request

          expect(log).to match /\[httplog\] GET http:\/\/#{host}:#{port}#{path}(\?.*)? completed with status code \d{3} in (\d|\.)+/
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Connecting: #{host}:#{port}")
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Response:")
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Data:")
          expect(log).to_not include(HttpLog::LOG_PREFIX + "Benchmark: ")
        end
      end

      context "with log4r" do
        it "works" do
          require 'log4r'
          require 'log4r/yamlconfigurator'
          require 'log4r/outputter/datefileoutputter'
          log4r_config= YAML.load_file(File.join(File.dirname(__FILE__),"support/log4r.yml"))
          Log4r::YamlConfigurator.decode_yaml( log4r_config['log4r_config'] )
          HttpLog.options[:logger] = Log4r::Logger['test']

          expect { adapter.send_get_request }.to_not raise_error
        end
      end
    end
  end

end
