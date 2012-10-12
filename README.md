## httplog

Log outgoing HTTP requests made from your application.

### Installation

  gem install httplog

### Usage

  require 'httplog'

By default, this will log all outgoing HTTP requests and their responses to $stdout on DEBUG level.

### Configuration

You can override the following default options:

  HttpLog.options[:logger]        = Logger.new($stdout)
  HttpLog.options[:severity]      = Logger::Severity::DEBUG
  HttpLog.options[:log_connect]   = true
  HttpLog.options[:log_request]   = true
  HttpLog.options[:log_data]      = true
  HttpLog.options[:log_status]    = true
  HttpLog.options[:log_response]  = true
  HttpLog.options[:log_benchmark] = true
  HttpLog.options[:compact_log]   = false # setting this to true will make all "log_*" options redundant

So if you want to use this in a Rails app:

  # file: config/initializers/httplog.rb

  HttpLog.options[:logger] = Rails.logger

### Running the specs

Make sure you have the necessary dependencies installed by running `bundle install`.
Then simple run `bundle exec rspec spec`.
This will launch a simple rack server on port 9292 and run all tests locally against that server.

### Contributing

If you have any issues with httplog,
or feature requests,
please [add an issue](https://github.com/trusche/httplog/issues) on GitHub
or fork the project and send a pull request.