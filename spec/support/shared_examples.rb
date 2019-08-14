RSpec.shared_examples 'logs request' do |method|
  subject { log }
  it { is_expected.to include(HttpLog::LOG_PREFIX + "Sending: #{method} http://#{host}:#{port}#{path}") }
end

RSpec.shared_examples 'logs nothing' do
  subject { log }
  it { is_expected.to eq('') }
end

RSpec.shared_examples 'logs expected response' do
  it { is_expected.to include("Response:#{adapter.expected_response_body}") }
end

RSpec.shared_examples 'logs data' do
  # Some adapters (YOU, Faraday!) re-order the keys for no bloody
  # reason whatsover. So we need to check them individually. And some
  # (guess who?) use non-standard URL encoding for spaces...
  it do
    data.split('&').each do |param|
      is_expected.to match(Regexp.new(param.gsub(' ', '( |%20|\\\+)')))
    end
  end
end

RSpec.shared_examples 'logs status' do |status|
  it { is_expected.to include(["Status:", status].compact.join(' ')) }
end

RSpec.shared_examples 'logs benchmark' do
  it { is_expected.to match(/Benchmark: \d+\.\d+ seconds/) }
end

RSpec.shared_examples 'data logging disabled' do
  let(:log_data) { false }
  it { is_expected.to_not include('Data:') }
end

RSpec.shared_examples 'response logging disabled' do
  let(:log_response) { false }
  it { is_expected.to_not include('Response:') }
end

RSpec.shared_examples 'benchmark logging disabled' do
  let(:log_benchmark) { false }
  it { is_expected.to_not include('Benchmark:') }
end

RSpec.shared_examples 'with prefix response lines' do
  let(:prefix_response_lines) { true }
  it { is_expected.to include('Response:') }
  it { is_expected.to include('<html>') }
end

RSpec.shared_examples 'with line numbers' do
  let(:prefix_response_lines) { true }
  let(:prefix_line_numbers) { true }
  it { is_expected.to include('Response:') }
  it { is_expected.to include('1: <html>') }
end

RSpec.shared_examples 'with request logging disabled' do
  let(:log_request) { false }
  it { is_expected.to_not include('Sending: GET') }
end

RSpec.shared_examples 'with connection logging disabled' do
  let(:log_connect) { false }
  it { is_expected.to_not include('Connecting:') }
end

RSpec.shared_examples 'filtered parameters' do
  let(:filter_parameters) { %w(foo) }

  it 'masks the filtered value' do
    # is_expected.to match(/foo(:?=|\"=>\"\[FILTERED\])/)
    is_expected.to_not include('my secret')
  end
end

RSpec.shared_examples 'filters password' do
  let(:data) { "password=secret&foo=bar" }

  it 'masks the filtered value' do
    is_expected.to include('password=[FILTERED]')
    is_expected.to_not include('secret')
  end
end

RSpec.shared_examples 'logs JSON' do |adapter_class, gray|
  if adapter_class.method_defined? :send_post_request
    before { adapter.send_post_request }
    let(:result) { gray ? gray_log : json }

    it { expect(result['method']).to eq('POST') }
    it { expect(result['request_body']).to eq(data) }
    it { expect(result['request_headers']).to be_a(Hash) }
    it { expect(result['response_headers']).to be_a(Hash) }
    it { expect(result['response_code']).to eq(200) }
    it { expect(result['response_body']).to eq(html) }
    it { expect(result['benchmark']).to be_a(Numeric) }
    if gray
      it { expect(result['short_message']).to be_a(String) }
    end
    it_behaves_like 'filtered parameters'

    context 'and compact config' do
      let(:compact_log) { true }

      it { expect(result['method']).to eq('POST') }
      it { expect(result['request_body']).to be_nil }
      it { expect(result['request_headers']).to be_nil }
      it { expect(result['response_headers']).to be_nil }
      it { expect(result['response_code']).to eq(200) }
      it { expect(result['response_body']).to be_nil }
      it { expect(result['benchmark']).to be_a(Numeric) }
    end
  end
end

RSpec.shared_examples 'with masked JSON' do |adapter_class|
  if adapter_class.method_defined? :send_post_request
    let(:json_log)  { true }
    let(:path)      { '/index.json' }
    let(:headers)   { { 'accept' => 'application/json', 'foo' => secret, 'content-type' => 'application/json' } }
    let(:data) do
      '{"foo":"mysecret","bar":"baz","array":[{"foo":"mysecret","bar":"baz"},{"hash":{"foo":"mysecret","bar":"baz"}}]}'
    end
    let(:filter_parameters) { %w[foo] }
    before { adapter.send_post_request }

    it { expect(json['request_headers'].to_s).not_to include(secret) }
    it { expect(json['request_body'].to_s).to include('hash') }
    it { expect(json['request_body'].to_s).to include('[FILTERED]') }
    it { expect(json['request_body'].to_s).not_to include(secret) }

    it { expect(json['response_body'].to_s).to include('hash') }
    it { expect(json['response_body'].to_s).to include('[FILTERED]') }
    it { expect(json['response_body'].to_s).not_to include(secret) }
  end
end
