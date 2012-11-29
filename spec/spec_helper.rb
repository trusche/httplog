$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'rspec'
require 'httpclient'
require 'excon'
require 'typhoeus'
require 'ethon'

require 'httplog'
require 'rack'
require 'adapters/http_base_adapter'


# Include all files under spec/support
Dir["./spec/support/**/*.rb"].each {|f| require f}

# Start a local rack server to serve up test pages.
@server_thread = Thread.new do
  Rack::Handler::Thin.run Httplog::Test::Server.new, :Port => 9292
end
sleep(1) # wait a sec for the server to be booted

RSpec.configure do |config|

  config.before(:each) do
    require 'stringio'

    @log = StringIO.new
    @logger = Logger.new @log

    HttpLog.reset_options!
    HttpLog.options[:logger] = @logger
  end

  def log
    @log.string
  end
end

