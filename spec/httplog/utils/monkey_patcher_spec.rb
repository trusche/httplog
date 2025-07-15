# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HttpLog::Utils::MonkeyPatcher do
  describe '.apply' do
    subject { described_class.apply(configuration) }

    let(:configuration) { HttpLog.configuration }

    context 'with default configuration' do
      before do
        allow(Net::HTTP).to receive(:prepend)
      end

      it 'applies default patches' do
        subject

        expect(HttpLog.configuration.enabled_patches).to eq([:net_http])
        expect(Net::HTTP).to have_received(:prepend).with(HttpLog::Net::HTTP)
      end
    end

    context 'with custom configuration' do
      let(:enabled_patches) { HttpLog::Utils::MonkeyPatcher.registered_patches.keys }

      before do
        configuration.enabled_patches = enabled_patches
      end

      before do
        allow(Net::HTTP).to receive(:prepend)
        allow(HTTPClient).to receive(:prepend)
        allow(HTTPClient::Session).to receive(:prepend)
        allow(Excon::Socket).to receive(:prepend)
        allow(Excon::Connection).to receive(:prepend)
        allow(HTTP::Client).to receive(:prepend)
        allow(HTTP::Connection).to receive(:prepend)
        allow(Patron::Session).to receive(:prepend)
      end

      it 'applies all custom patches' do
        subject

        expect(HttpLog.configuration.enabled_patches).to eq(enabled_patches)
        expect(HTTPClient::Session).to have_received(:prepend).with(HttpLog::HTTPClient::SessionLatest)
        expect(HTTPClient).to have_received(:prepend).with(HttpLog::HTTPClient).twice
        expect(Excon::Socket).to have_received(:prepend).with(HttpLog::Excon::Socket)
        expect(Excon::Connection).to have_received(:prepend).with(HttpLog::Excon::Connection)
        expect(HTTP::Client).to have_received(:prepend).with(HttpLog::HTTPClientInstrumentation)
        expect(HTTP::Connection).to have_received(:prepend).with(HttpLog::HTTPConnectionInstrumentation)
        expect(Patron::Session).to have_received(:prepend).with(HttpLog::Patron::Session)
      end
    end
  end

  describe '.register_patch' do
    let(:target) { Class.new }
    let(:patch) { Module.new }

    context 'when providing both a block and a patch' do
      it 'raises an ArgumentError' do
        expect {
          described_class.register_patch(:test_patch, patch, target) { puts 'patch' }
        }.to raise_error(ArgumentError, 'Please provide either a patch and its target OR a block, but not both')
      end
    end

    context 'when providing a patch and target' do
      it 'registers the patch properly' do
        described_class.register_patch(:test_patch, patch, target)
        expect(described_class.registered_patches[:test_patch]).to be_a(Proc)
      end
    end

    context 'when providing a block' do
      it 'registers the block as a patch' do
        block = proc { puts 'patch applied' }

        described_class.register_patch(:test_patch, &block)
        expect(described_class.registered_patches[:test_patch]).to eq(block)
      end
    end
  end

  describe '.validate!' do
    subject { described_class.validate!(patches) }

    before { allow(described_class).to receive(:registered_patches).and_return(registered_patches) }

    context 'when all patches are registered' do
      let(:registered_patches) { { foo: proc {}, bar: proc {} } }
      let(:patches) { %i[foo bar] }

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when some patches are not registered' do
      let(:registered_patches) { { foo: proc {} } }
      let(:patches) { %i[foo bar] }

      it 'raises a PatchesError' do
        expect { subject }.to raise_error(HttpLog::Configuration::PatchesError, /Please check registered patches/)
      end
    end
  end
end
