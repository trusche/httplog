## httplog

Log outgoing HTTP requests made from your application.
See the [blog post](http://trusche.github.com/blog/2011/09/29/logging-outgoing-http-requests/)
for more details.

So far this gem works with the following ruby modules and libraries:

* [Net::HTTP](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/index.html)
* [OpenURI](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/open-uri/rdoc/index.html)
* [Excon](https://github.com/geemus/excon)
* [HTTPClient](https://github.com/nahi/httpclient)
* [HTTParty](https://github.com/jnunemaker/httparty)

In theory, it should also work with any library built on top of these. But since
the difference between theory and practice is bigger in practice than in theory, YMMV.

This is very much a development and debugging tool; it is **not recommended** to
use this in a production environment.

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
    HttpLog.options[:log_headers]   = false
    HttpLog.options[:log_data]      = true
    HttpLog.options[:log_status]    = true
    HttpLog.options[:log_response]  = true
    HttpLog.options[:log_benchmark] = true
    HttpLog.options[:compact_log]   = false # setting this to true will make all "log_*" options redundant

So if you want to use this in a Rails app:

    # config/initializers/httplog.rb
    HttpLog.options[:logger] = Rails.logger

### Example

With the default configuration, the log output might look like this:

    D, [2012-11-21T15:09:03.532970 #6857] DEBUG -- : [httplog] Connecting: localhost:80
    D, [2012-11-21T15:09:03.533877 #6857] DEBUG -- : [httplog] Sending: GET http://localhost:9292/index.html
    D, [2012-11-21T15:09:03.534499 #6857] DEBUG -- : [httplog] Status: 200
    D, [2012-11-21T15:09:03.534544 #6857] DEBUG -- : [httplog] Benchmark: 0.00057 seconds
    D, [2012-11-21T15:09:03.534578 #6857] DEBUG -- : [httplog] Response:
    <html>
      <head>
        <title>Test Page</title>
      </head>
      <body>
        <h1>This is the test page.</h1>
      </body>
    </html>


### Known Issues

* When using OpenURI, the reading of the HTTP response body is deferred,
  so it is not available for logging. This will be noted in the logging statement:

        D, [2012-11-21T15:09:03.547005 #6857] DEBUG -- : [httplog] Connecting: localhost:80
        D, [2012-11-21T15:09:03.547938 #6857] DEBUG -- : [httplog] Sending: GET http://localhost:9292/index.html
        D, [2012-11-21T15:09:03.548615 #6857] DEBUG -- : [httplog] Status: 200
        D, [2012-11-21T15:09:03.548662 #6857] DEBUG -- : [httplog] Benchmark: 0.000617 seconds
        D, [2012-11-21T15:09:03.548695 #6857] DEBUG -- : [httplog] Response: (not available yet)

*  When using HTTPClient, the TCP connection establishment will be logged
   *after* the HTTP request and headers, due to the way HTTPClient is organized.

        D, [2012-11-22T18:39:46.031698 #12800] DEBUG -- : [httplog] Sending: GET http://localhost:9292/index.html
        D, [2012-11-22T18:39:46.031756 #12800] DEBUG -- : [httplog] Header: accept: */*
        D, [2012-11-22T18:39:46.031788 #12800] DEBUG -- : [httplog] Header: foo: bar
        D, [2012-11-22T18:39:46.031942 #12800] DEBUG -- : [httplog] Connecting: localhost:9292
        D, [2012-11-22T18:39:46.033409 #12800] DEBUG -- : [httplog] Status: 200
        D, [2012-11-22T18:39:46.033483 #12800] DEBUG -- : [httplog] Benchmark: 0.001562 seconds

* When using Ethon, the TCP connection is not logged (since it's established by libcurl).

### Running the specs

Make sure you have the necessary dependencies installed by running `bundle install`.
Then simply run `bundle exec rspec spec`.
This will launch a simple rack server on port 9292 and run all tests locally against that server.

### Contributing

If you have any issues with httplog,
or feature requests,
please [add an issue](https://github.com/trusche/httplog/issues) on GitHub
or fork the project and send a pull request.
Please include passing specs with all pull requests.

### Contributors

Thanks to these fine folks for contributing pull requests:

* [Eric Cohen](https://github.com/eirc)
* [Nikos Dimitrakopoulos](https://github.com/nikosd)
* [Marcos Hack](https://github.com/marcoshack)
