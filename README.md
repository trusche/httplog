## httplog

[![Gem Version](https://badge.fury.io/rb/httplog.svg)](http://badge.fury.io/rb/httplog) [![Build Status](https://travis-ci.org/trusche/httplog.svg?branch=master)](https://travis-ci.org/trusche/httplog) [![Code Climate](https://codeclimate.com/github/trusche/httplog.svg)](https://codeclimate.com/github/trusche/httplog)
[![Release Version](https://img.shields.io/github/release/trusche/httplog.svg)](https://img.shields.io/github/release/trusche/httplog.svg)

Log outgoing HTTP requests made from your application. Helps with debugging pesky API error responses, or just generally understanding what's going on under the hood.

Requires ruby >= 2.4.

This gem works with the following ruby modules and libraries:

* [Net::HTTP](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/net/http/rdoc/index.html)
* [Ethon](https://github.com/typhoeus/ethon)
* [Excon](https://github.com/geemus/excon)
* [OpenURI](http://www.ruby-doc.org/stdlib-1.9.3/libdoc/open-uri/rdoc/index.html)
* [Patron](https://github.com/toland/patron)
* [HTTPClient](https://github.com/nahi/httpclient)
* [HTTParty](https://github.com/jnunemaker/httparty)
* [HTTP](https://github.com/httprb/http)

These libraries are at least partially supported, where they use one of the above as adapters, but not explicitly tested - YMMV:

* [Faraday](https://github.com/technoweenie/faraday)
* [Typhoeus](https://github.com/typhoeus/typhoeus)

In theory, it should also work with any library built on top of these. But the difference between theory and practice is bigger in practice than in theory.

This is very much a development and debugging tool; it is **not recommended** to
use this in a production environment as it is monkey-patching the respective HTTP implementations.
You have been warned - use at your own risk.

### Installation

    gem install httplog

### Usage

    require 'httplog' # require this *after* your HTTP gem of choice

By default, this will log all outgoing HTTP requests and their responses to $stdout on DEBUG level.

### Notes on content types

* Binary data from response bodies (as indicated by the `Content-Type` header)is not logged.
* Text data (`text/*` and most `application/*` types) is encoded as UTF-8, with invalid characters replaced. If you need to inspect raw non-UTF data exactly as sent over the wire, this tool is probably not for you.

### Configuration

You can override the following default options:

```ruby
HttpLog.configure do |config|

  # Enable or disable all logging
  config.enabled = true

  # You can assign a different logger or method to call on that logger
  config.logger = Logger.new($stdout)
  config.logger_method = :log

  # I really wouldn't change this...
  config.severity = Logger::Severity::DEBUG

  # Tweak which parts of the HTTP cycle to log...
  config.log_connect   = true
  config.log_request   = true
  config.log_headers   = false
  config.log_data      = true
  config.log_status    = true
  config.log_response  = true
  config.log_benchmark = true

  # ...or log all request as a single line by setting this to `true`
  config.compact_log = false

  # You can also log in JSON format
  config.json_log = false

  # Prettify the output - see below
  config.color = false

  # Limit logging based on URL patterns
  config.url_whitelist_pattern = nil
  config.url_blacklist_pattern = nil

  # Mask the values of sensitive requestparameters
  config.filter_parameters = %w[password]
end
```

If you want to use this in a Rails app, I'd suggest configuring this specifically for each environment. A global initializer is not a good idea since `HttpLog` will be undefined in production. Because you're **not using this in production**, right? :)

```ruby
# config/environments/development.rb

HttpLog.configure do |config|
  config.logger = Rails.logger
end
```

If you're running a (hopefully patched) legacy Rails 3 app, you may need to set
`config.logger_method = :add` due to its somewhat unusual logger.

You can colorize the output to make it stand out in your logfile, either with a single color
for the text:

```ruby
HttpLog.configure do |config|
  config.color = :red
end
```

Or with a color hash for text and background:

```ruby
HttpLog.configure do |config|
  config.color = {color: :black, background: :yellow}
end
```

For more color options please refer to the [rainbow documentation](https://github.com/sickill/rainbow)

### Compact logging

If the log is too noisy for you, but you don't want to completely disable it either, set the `compact_log` option to `true`. This will log each request in a single line with method, request URI, response status and time, but no data or headers. No need to disable any other options individually.

### JSON logging

If you want to log HTTP requests in a JSON format, set the `json_log` option to `true`. You can combine this with `compact_log` to only log the basic request metrics without headers and bodies.

### Parameter filtering

Just like in Rails, you can filter the values of sensitive parameters by setting the `filter_parameters` to an array of (lower case) keys. The value for "password" is filtered by default.

**Please note** that this will **only filter the request data** with well-formed parameters (in the URL, the headers, and the request data) but **not the response**. It does not currently filter JSON request data either, just standard "key=value" pairs in the request body.

### Example

With the default configuration, the log output might look like this:

    [httplog] Connecting: localhost:80
    [httplog] Sending: GET http://localhost:9292/index.html
    [httplog] Status: 200
    [httplog] Benchmark: 0.00057 seconds
    [httplog] Response:
    <html>
      <head>
        <title>Test Page</title>
      </head>
      <body>
        <h1>This is the test page.</h1>
      </body>
    </html>

With `log_headers = true` and a parameter 'password' in the request query and headers:


    [httplog] Connecting: localhost:80
    [httplog] Sending: GET http://localhost:9292/index.html?password=[FILTERED]
    [httplog] Header: accept: *.*
    [httplog] Header: password=[FILTERED]
    [httplog] Status: 200
    [httplog] Benchmark: 0.00057 seconds
    [httplog] Response:
    <html>
      <head>
        <title>Test Page</title>
      </head>
      <body>
        <h1>This is the test page.</h1>
      </body>
    </html>

With `compact_log` enabled, the same request might look like this:

    [httplog] GET http://localhost:9292/index.html completed with status code 200 in 0.00057 seconds

With `json_log` enabled:

    [httplog] {"method":"GET","url":"localhost:80","request_body":null, "request_headers":{"foo":"bar"}, "response_code":200,"response_body":"<html>\n      <head>\n        <title>Test Page</title>\n      </head>\n      <body>\n        <h1>This is the test page.</h1>\n      </body>\n    </html>","response_headers":{"foo":"bar"},"benchmark":0.00057}

And with `json_log` *and* `compact_log` enabled:

    [httplog] {"method":"GET","url":"localhost:80","response_code":200,"benchmark":0.00057}

### Known Issues

Following are some known quirks and issues with particular libraries. If you know a workaround or have
a suggestion for a fix, please open an issue or, even better, submit a pull request!

* Requests types other than GET and POST have not been explicitly tested.
  They may or may not be logged, depending on the implementation details of the underlying library.
  If they are not for a particular library, please feel free to open an issue with the details.

* When using OpenURI, the reading of the HTTP response body is deferred,
  so it is not available for logging. This will be noted in the logging statement:

        [httplog] Connecting: localhost:80
        [httplog] Sending: GET http://localhost:9292/index.html
        [httplog] Status: 200
        [httplog] Benchmark: 0.000617 seconds
        [httplog] Response: (not available yet)

*  When using HTTPClient, the TCP connection establishment will be logged
   *after* the HTTP request and headers, due to the way HTTPClient is organized.

        [httplog] Sending: GET http://localhost:9292/index.html
        [httplog] Header: accept: */*
        [httplog] Header: foo: bar
        [httplog] Connecting: localhost:9292
        [httplog] Status: 200
        [httplog] Benchmark: 0.001562 seconds

* Also when using HTTPClient, make sure you include `httplog` **after** `httpclient` in your `Gemfile`.

* When using Ethon or Patron, and any library based on them (such as Typhoeus),
  the TCP connection is not logged (since it's established by libcurl).

* Benchmarking only covers the time between starting the HTTP request and receiving the response. It does *not* cover the time it takes to establish the TCP connection.

* When using [REST Client](https://github.com/rest-client/rest-client), POST requests might be missing the requests
  data. See #54 for details.

### Running the specs

Make sure you have the necessary dependencies installed by running `bundle install`.
Then simply run `bundle exec rspec spec`.
This will launch a simple rack server on port 9292 and run all tests locally against that server.

### Contributing

If you have any issues with or feature requests for httplog,
please [open an issue](https://github.com/trusche/httplog/issues) on GitHub
or fork the project and send a pull request. **Please include passing specs with all pull requests.**

### Contributors

Thanks to these fine folks for contributing pull requests:

* [Doug Johnston](https://github.com/dougjohnston)
* [Eric Cohen](https://github.com/eirc)
* [Nikos Dimitrakopoulos](https://github.com/nikosd)
* [Marcos Hack](https://github.com/marcoshack)
* [Andrew Hammond](https://github.com/andrhamm)
* [Chris Keele](https://github.com/christhekeele)
* [Ryan Souza](https://github.com/ryansouza)
* [Ilya Bondarenko](https://github.com/sedx)
* [Kostas Zacharakis](https://github.com/kzacharakis)
* [Yuri Smirnov](https://github.com/tycooon)
* [Manuel Bustillo Alonso](https://github.com/bustikiller)
