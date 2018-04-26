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
  end
end
