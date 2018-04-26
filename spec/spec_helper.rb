# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'httpclient'
require 'excon'
# require 'typhoeus'
require 'ethon'
require 'patron'
require 'http'
require 'simplecov'

SimpleCov.start

require 'httplog'

require 'adapters/http_base_adapter'
Dir[File.dirname(__FILE__) + '/adapters/*.rb'].each { |f| require f }
Dir['./spec/support/**/*.rb'].each { |f| require f }

# Start a local rack server to serve up test pages.
@server_thread = Thread.new do
  Rack::Handler::Thin.run Httplog::Test::Server.new, Port: 9292
end
sleep(3) # wait a moment for the server to be booted

RSpec.configure do |config|
  config.before(:each) do
    require 'stringio'

    @log = StringIO.new
    @logger = Logger.new @log

    HttpLog.configure { |c| c.logger = @logger }
  end

  config.after(:each) do
    HttpLog.reset!
  end

  def log
    @log.string
  end
end
