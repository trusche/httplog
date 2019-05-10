# frozen_string_literal: true

require 'spec_helper'

describe HttpLog do
  subject { log } # see spec_helper

  let(:host)    { 'localhost' }
  let(:port)    { 9292 }
  let(:path)    { '/index.html' }
  let(:headers) { { 'accept' => '*/*', 'foo' => 'bar', 'secret' => '1234', 'password' => '5678' } }
  let(:data)    { 'foo=bar&bar=foo&secret=1234&password=5678' }
  let(:params)  { { 'foo' => 'bar:form-data', 'bar' => 'foo', 'secret' => '1234', 'password' => '5678' } }
  let(:html)    { File.read('./spec/support/index.html') }
  let(:json)    { JSON.parse(log.match(/\[httplog\]\s(.*)/).captures.first) }

  # Configuration
  let(:enabled)               { HttpLog.configuration.enabled }
  let(:severity)              { HttpLog.configuration.severity }
  let(:log_headers)           { HttpLog.configuration.log_headers }
  let(:log_request)           { HttpLog.configuration.log_request }
  let(:log_response)          { HttpLog.configuration.log_response }
  let(:log_data)              { HttpLog.configuration.log_data }
  let(:log_connect)           { HttpLog.configuration.log_connect }
  let(:log_benchmark)         { HttpLog.configuration.log_benchmark }
  let(:color)                 { HttpLog.configuration.color }
  let(:prefix)                { HttpLog.configuration.prefix }
  let(:prefix_response_lines) { HttpLog.configuration.prefix_response_lines }
  let(:prefix_line_numbers)   { HttpLog.configuration.prefix_line_numbers }
  let(:json_log)              { HttpLog.configuration.json_log }
  let(:compact_log)           { HttpLog.configuration.compact_log }
  let(:url_blacklist_pattern) { HttpLog.configuration.url_blacklist_pattern }
  let(:url_whitelist_pattern) { HttpLog.configuration.url_whitelist_pattern }
  let(:filtered_keywords)     { HttpLog.configuration.filtered_keywords }

  def configure
    HttpLog.configure do |c|
      c.enabled               = enabled
      c.severity              = severity
      c.log_headers           = log_headers
      c.log_request           = log_request
      c.log_response          = log_response
      c.log_data              = log_data
      c.log_connect           = log_connect
      c.log_benchmark         = log_benchmark
      c.color                 = color
      c.prefix                = prefix
      c.prefix_response_lines = prefix_response_lines
      c.prefix_line_numbers   = prefix_line_numbers
      c.json_log              = json_log
      c.compact_log           = compact_log
      c.url_blacklist_pattern = url_blacklist_pattern
      c.url_whitelist_pattern = url_whitelist_pattern
      c.filtered_keywords     = filtered_keywords
    end
  end

  ADAPTERS = [
    NetHTTPAdapter,
    OpenUriAdapter,
    HTTPClientAdapter,
    HTTPartyAdapter,
    FaradayAdapter,
    ExconAdapter,
    EthonAdapter,
    PatronAdapter,
    HTTPAdapter
  ].freeze

  ADAPTERS.each do |adapter_class|
    context adapter_class, adapter: adapter_class.to_s do
      let(:adapter) { adapter_class.new(host: host, port: port, path: path, headers: headers, data: data, params: params) }
      before { configure }

      context 'with default configuration' do
        describe 'GET requests' do
          let!(:res) { adapter.send_get_request }

          it_behaves_like 'logs request', 'GET'
          it_behaves_like 'logs data'
          it_behaves_like 'logs expected response'
          it_behaves_like 'logs status', 200
          it_behaves_like 'logs benchmark'

          it { is_expected.to_not include('Header:') }
          it { is_expected.to_not include("\e[0") }

          unless adapter_class.is_libcurl?
            it { is_expected.to include("Connecting: #{host}:#{port}") }
          end

          it { expect(res).to be_a adapter.response if adapter.respond_to? :response }

          context 'with gzip encoding' do
            let(:path) { '/index.html.gz' }
            let(:data) { nil }

            it_behaves_like 'logs expected response'

            if adapter_class.method_defined? :send_head_request
              it "doesn't try to decompress body for HEAD requests" do
                expect(log).to include('Response:')
              end
            end
          end

          context 'with UTF-8 response body' do
            let(:path) { '/utf8.html' }
            let(:data) { nil }

            it_behaves_like 'logs expected response'
            it { is_expected.to include('    <title>Блог Яндекса</title>') if adapter.logs_data? }
          end

          context 'with binary response body' do
            %w[/test.bin /test.pdf].each do |response_file_name|
              let(:path) { response_file_name }
              let(:data) { nil }

              it { is_expected.to include('Response: (not showing binary data)') }

              context 'and JSON logging' do
                let(:json_log) { true }
                it { expect(json['response_body']).to eq '(not showing binary data)' }
              end
            end
          end
        end

        describe 'POST requests' do
          if adapter_class.method_defined? :send_post_request
            let!(:res) { adapter.send_post_request }

            unless adapter_class.is_libcurl?
              it { is_expected.to include("Connecting: #{host}:#{port}") }
            end

            it_behaves_like 'logs request', 'POST'
            it_behaves_like 'logs expected response'
            it_behaves_like 'logs data', 'foo=bar&bar=foo'
            it_behaves_like 'logs status', 200
            it_behaves_like 'logs benchmark'

            it { is_expected.to_not include('Header:') }

            it { expect(res).to be_a adapter.response if adapter.respond_to? :response }

            context 'with non-UTF request data' do
              let(:data) { "a UTF-8 striñg with an 8BIT-ASCII character: \xC3" }
              it_behaves_like 'logs expected response' # == doesn't throw exception
            end

            context 'with URI encoded non-UTF data' do
              let(:data) { 'a UTF-8 striñg with a URI encoded 8BIT-ASCII character: %c3' }
              it_behaves_like 'logs expected response' # == doesn't throw exception
            end
          end
        end
      end

      context 'with custom configuration' do
        context 'GET requests' do
          before { adapter.send_get_request }

          context 'when disabled' do
            let(:enabled) { false }
            it_behaves_like 'logs nothing'
          end

          context 'with different log level' do
            let(:severity) { Logger::Severity::INFO }
            it { is_expected.to include('INFO') }
          end

          context 'with headers logging' do
            let(:log_headers) { true }
            it { is_expected.to match(%r{Header: accept: */*}i) } # request
            it { is_expected.to match(/Header: Server: thin/i) } # response
          end

          context 'with blacklist hit' do
            let(:url_blacklist_pattern) { /#{host}:#{port}/ }
            it_behaves_like 'logs nothing'
          end

          context 'with blacklist miss' do
            let(:url_blacklist_pattern) { /example.com/ }
            it_behaves_like 'logs request', 'GET'
          end

          context 'with whitelist hit' do
            let(:url_whitelist_pattern) { /#{host}:#{port}/ }
            it_behaves_like 'logs request', 'GET'

            context 'and blacklist hit' do
              let(:url_blacklist_pattern) { /#{host}:#{port}/ }
              it_behaves_like 'logs nothing'
            end
          end

          context 'with whitelist miss' do
            let(:url_whitelist_pattern) { /example.com/ }
            it_behaves_like 'logs nothing'
          end

          it_behaves_like 'with request logging disabled'
          it_behaves_like 'with connection logging disabled'
          it_behaves_like 'data logging disabled'
          it_behaves_like 'response logging disabled'
          it_behaves_like 'benchmark logging disabled'

          context 'with single color' do
            let(:color) { :red }
            it { is_expected.to include("\e[31m") }
          end

          context 'with color hash' do
            let(:color) { { color: :black, background: :yellow } }
            it { is_expected.to include("\e[30m\e[43m") }
          end

          context 'with custom prefix' do
            let(:prefix) { '[my logger]' }
            it { is_expected.to include('[my logger]') }
            it { is_expected.to_not include(HttpLog::LOG_PREFIX) }
          end

          context 'with custom lambda prefix' do
            let(:prefix) { -> { '[custom prefix]' } }
            it { is_expected.to include('[custom prefix]') }
            it { is_expected.to_not include(HttpLog::LOG_PREFIX) }
          end

          context 'with compact config' do
            let(:compact_log) { true }
            it { is_expected.to match(%r{\[httplog\] GET http://#{host}:#{port}#{path}(\?.*)? completed with status code \d{3} in (\d|\.)+}) }
            it { is_expected.to_not include("Connecting: #{host}:#{port}") }
            it { is_expected.to_not include('Response:') }
            it { is_expected.to_not include('Data:') }
            it { is_expected.to_not include('Benchmark: ') }
          end
        end

        context 'POST requests' do
          if adapter_class.method_defined? :send_post_request
            before { adapter.send_post_request }

            it_behaves_like 'data logging disabled'
            it_behaves_like 'response logging disabled'
            it_behaves_like 'benchmark logging disabled'
            it_behaves_like 'with prefix response lines'
            it_behaves_like 'with line numbers'
          end
        end

        context 'POST form data requests' do
          if adapter_class.method_defined? :send_post_form_request
            before { adapter.send_post_form_request }

            it_behaves_like 'data logging disabled'
            it_behaves_like 'response logging disabled'
            it_behaves_like 'benchmark logging disabled'
            it_behaves_like 'with prefix response lines'
            it_behaves_like 'with line numbers'
          end
        end

        context 'POST multi-part requests (file upload)' do
          let(:upload) { Tempfile.new('http-log') }
          let(:params) { { 'foo' => 'bar', 'file' => upload } }

          if adapter_class.method_defined? :send_multipart_post_request
            before { adapter.send_multipart_post_request }

            it_behaves_like 'data logging disabled'
            it_behaves_like 'response logging disabled'
            it_behaves_like 'benchmark logging disabled'
            it_behaves_like 'with prefix response lines'
            it_behaves_like 'with line numbers'
          end
        end
      end

      context 'with JSON config' do
        let(:json_log) { true }

        if adapter_class.method_defined? :send_post_request
          before { adapter.send_post_request }

          it { expect(json['method']).to eq('POST') }
          it { expect(json['request_body']).to eq(data) }
          it { expect(json['request_headers']).to be_a(Hash) }
          it { expect(json['response_headers']).to be_a(Hash) }
          it { expect(json['response_code']).to eq(200) }
          it { expect(json['response_body']).to eq(html) }
          it { expect(json['benchmark']).to be_a(Numeric) }

          context 'and compact config' do
            let(:compact_log) { true }

            it { expect(json['method']).to eq('POST') }
            it { expect(json['request_body']).to be_nil }
            it { expect(json['request_headers']).to be_nil }
            it { expect(json['response_headers']).to be_nil }
            it { expect(json['response_code']).to eq(200) }
            it { expect(json['response_body']).to be_nil }
            it { expect(json['benchmark']).to be_a(Numeric) }
          end
        end
      end

      context 'with filtered keywords' do
        let(:filtered_keywords) { %w(secret password) }
        let(:log_headers) { true }

        context 'POST' do
          if adapter_class.method_defined? :send_post_request
            before { adapter.send_post_request }
            it_behaves_like 'filters out keywords'
          end
        end

        context 'POST form' do
          if adapter_class.method_defined? :send_post_form_request
            before { adapter.send_post_form_request }
            it_behaves_like 'filters out keywords'
          end
        end

        context 'GET' do
          before { adapter.send_get_request }
          it_behaves_like 'filters out keywords'
        end

        context 'with JSON logging' do
          let(:json_log) { true }

          context 'POST' do
            if adapter_class.method_defined? :send_post_request
              before { adapter.send_post_request }
              it_behaves_like 'filters out keywords'
            end
          end
        end
      end
    end
  end
end
