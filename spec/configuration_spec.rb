# frozen_string_literal: true

require 'spec_helper'

module HttpLog
  describe Configuration do
    let(:config) { described_class.new }

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

    describe '#enabled_patches=' do
      subject { config.enabled_patches = patches }

      context 'when patches invalid' do
        let(:patches) { %i[foo bar] }

        it 'raises an error' do
          expect { subject }.to raise_error(HttpLog::Configuration::PatchesError)
        end
      end

      context 'with valid patches' do
        let(:patches) { %i[httpclient] }

        it 'successfully sets value' do
          expect(subject).to eq(patches)
        end
      end
    end
  end
end
