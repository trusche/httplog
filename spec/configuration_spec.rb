# frozen_string_literal: true

require 'spec_helper'

module HttpLog
  describe Configuration do
    let(:config) { Configuration.new }

    describe '#compact_log' do
      it 'defaults to false' do
        expect(config.compact_log).to eq(false)
      end
    end

    describe '#compact_log=' do
      it 'sets values' do
        config.compact_log = true
        expect(config.compact_log).to eq(true)
      end
    end

    describe '#log_headers' do
      subject { config.log_headers }

      before do
        config.log_headers          = log_headers
        config.log_request_headers  = log_request_headers
        config.log_response_headers = log_response_headers
      end

      context 'when `log_headers` is true' do
        let(:log_headers) { true }

        context 'and both `log_request_headers` and `log_reponse_headers` are false' do
          let(:log_request_headers) { false }
          let(:log_response_headers) { false }

          it { is_expected.to be_truthy }
        end

        context 'and both `log_request_headers` and `log_reponse_headers` are true' do
          let(:log_request_headers) { true }
          let(:log_response_headers) { true }

          it { is_expected.to be_falsey }
        end

        context 'when `log_request_headers` is true and `log_response_headers` is false' do
          let(:log_request_headers) { true }
          let(:log_response_headers) { false }

          it { is_expected.to be_falsey }
        end

        context 'when `log_request_headers` is false and `log_response_headers` is true' do
          let(:log_request_headers) { false }
          let(:log_response_headers) { true }

          it { is_expected.to be_falsey }
        end
      end

      context 'when `log_headers` is false' do
        let(:log_headers) { false }

        context 'and both `log_request_headers` and `log_reponse_headers` are false' do
          let(:log_request_headers) { false }
          let(:log_response_headers) { false }

          it { is_expected.to be_falsey }
        end

        context 'and both `log_request_headers` and `log_reponse_headers` are true' do
          let(:log_request_headers) { true }
          let(:log_response_headers) { true }

          it { is_expected.to be_falsey }
        end

        context 'when `log_request_headers` is true and `log_response_headers` is false' do
          let(:log_request_headers) { true }
          let(:log_response_headers) { false }

          it { is_expected.to be_falsey }
        end

        context 'when `log_request_headers` is false and `log_response_headers` is true' do
          let(:log_request_headers) { false }
          let(:log_response_headers) { true }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
