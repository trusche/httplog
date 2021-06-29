# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'httpclient'
require 'excon'
# require 'typhoeus'
require 'ethon'
require 'patron'
require 'restclient'
require 'http'
require 'simplecov'
require 'oj'

SimpleCov.start

require 'httplog'

require 'loggers/formatter'
require 'loggers/gelf_mock'
require 'adapters/http_base_adapter'
Dir[File.dirname(__FILE__) + '/adapters/*.rb'].each { |f| require f }
Dir['./spec/support/**/*.rb'].each { |f| require f }

# Start a local rack server to serve up test pages.
@server_thread = Thread.new do
  Rack::Handler::Thin.run Httplog::Test::Server.new, Port: 9292
end

# wait for the server to be booted
loop do
  TCPSocket.new('127.0.0.1', 9292).close
  break
rescue Errno::ECONNREFUSED
  sleep 0.1
  retry
end

RSpec.configure do |config|
  Oj.default_options = {mode: :compat}

  config.before(:each) do
    require 'stringio'

    @log = StringIO.new
  end

  config.after(:each) do
    HttpLog.reset!
  end

  def log
    @log.string
  end
end
