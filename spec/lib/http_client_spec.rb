# frozen_string_literal: true

require 'spec_helper'

describe HTTPClient do
  let(:client) { HTTPClient.new }

  it 'works with transparent_gzip_decompression' do
    client.transparent_gzip_decompression = true
    expect { client.get("http://localhost:9292/index.html.gz") }.to_not(raise_error)
    expect(log).to include(HttpLog::LOG_PREFIX + 'Status: 200')
    expect(log).to include(HttpLog::LOG_PREFIX + 'Data:')
    expect(log).to include(HttpLog::LOG_PREFIX + "Response:\n<html>")
  end
end
