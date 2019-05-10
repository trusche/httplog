RSpec.shared_examples 'logs request' do |method|
  subject { log }
  it { is_expected.to include(HttpLog::LOG_PREFIX + "Sending: #{method} http://#{host}:#{port}#{path}") }
end

RSpec.shared_examples 'logs nothing' do |method|
  subject { log }
  it { is_expected.to eq('') }
end

RSpec.shared_examples 'logs expected response' do
  it { is_expected.to include("Response:#{adapter.expected_response_body}") }
end

RSpec.shared_examples 'logs data' do |data|
  it { is_expected.to include(["Data:", data].compact.join(' ')) }
end

RSpec.shared_examples 'logs status' do |status|
  it { is_expected.to include(["Status:", status].compact.join(' ')) }
end

RSpec.shared_examples 'logs benchmark' do |data|
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

RSpec.shared_examples 'filters out keywords' do
  it { is_expected.to_not include('secret=1234') }
  it { is_expected.to_not include('secret: 1234') }
  it { is_expected.to_not include('password=5678') }
  it { is_expected.to_not include('password: 5678') }
end
