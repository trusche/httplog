## 1.6.2 - 2022-11-19

* Added rubygems.org metadata
* Gem dependency updates

## 1.6.0 - 2022-09-17

* Gem upgrades
* [#110](https://github.com/trusche/httplog/pull/110) Fix for empty body response
* [#111](https://github.com/trusche/httplog/pull/111) Removed runtime dependencies
* Dependency updates 
* Fix the missing Ethon log info #124

## 1.5.0 - 2021-05-20

* Support for Ruby 2.7 and frozen strings
* Development dependency updates
* Dropped support for net/http v3
* Performance tweaks
* Fix for RestClient body read issue (WARNING: this may be reverted, see [#105](https://github.com/trusche/httplog/issues/105))

## 1.4.3 - 2020-06-10

* Masking `password` parameter by default... doh.

## 1.4.2 - 2020-02-09

* Rollback of the previous two releases due to bugs introduced there.

## 1.4.1 - 2020-02-08 - YANKED

* [#91](https://github.com/trusche/httplog/pull/91) Fixed bug returning empty response with HTTP gem

## 1.4.0 - 2020-01-19 - YANKED

* [#85](https://github.com/trusche/httplog/pull/85) Parse JSON response and apply deep masking

## 1.3.3 - 2019-11-14

* [#83](https://github.com/trusche/httplog/pull/83) Support for graylog

## 1.3.1 - 2019-06-07

* [#76](https://github.com/trusche/httplog/pull/76) Added configurable logger method

## 1.3.0 - 2019-05-18

* [#74](https://github.com/trusche/httplog/pull/74) Added ability to filter sensitive parameter values in the request (based on [#73](https://github.com/trusche/httplog/pull/73)). Default masking of `password` parameter
* Removed explicit support and tests for ruby 2.3 and http gem v2
* [#71](https://github.com/trusche/httplog/pull/71) Rounding benchmark in compact mode

## 1.2.2 - 2019-03-15

* [#70](https://github.com/trusche/httplog/pull/70) Fixed a bug where blacklisting caused requests to not be sent with HTTP adapter

## 1.2.1 - 2019-01-28

* [#67](https://github.com/trusche/httplog/pull/67) Gracefully handling empty response headers in Ethon

## 1.2.0 - 2018-12-31

* [#65](https://github.com/trusche/httplog/pull/65) Added JSON as an optional output format
* Ruby 2.2 no longer supported

## 1.1.1 - 2018-06-30

* [#60](https://github.com/trusche/httplog/issues/60) Fixed a bug in color configuration settings

## 1.1.0 - 2018-06-22

* [#59](https://github.com/trusche/httplog/issues/59) Switched colorization library to MIT licensed [rainbow](https://github.com/sickill/rainbow).
  This is not a breaking change, but if you currently use a color name that is not defined by the Rainbow gem, it will
  simply be ignored.

## 1.0.3 - 2018-04-26

* [#58](https://github.com/trusche/httplog/issues/58) Fixed decompression error for HTTPClient with `transparent_gzip_decompression` enabled.
* Rubocop!

## 1.0.2 - 2018-02-26

* [#57](https://github.com/trusche/httplog/issues/57) Changed rack dependency to be less strict
* Updated travis to test against both major rack versions

## 1.0.1 - 2018-02-18

* [#56](https://github.com/trusche/httplog/pull/56) Fixed data logging for httprb v3 ([@tycooon])
* Cleaned up dependencies and requiring ruby version >= 2.2

## 1.0.0 - 2017-11-02

* [#53](https://github.com/trusche/httplog/pull/53) Fix header logging

## 0.99.7 - 2017-07-19

* Requiring `rack` explicitly so that plain ruby clients don't have to

## 0.99.6 - 2017-07-11

* Added `enabled` configuration option (default: true, doh)

## 0.99.5 - 2017-07-05

* Bugfix: Returning response for patron adapter

## 0.99.4 - 2017-06-12

* Bugfix: No longer modifying post data in place for safe logging

## 0.99.0 - 2017-02-28

* Proper configuration!

  If you're using any custom configuration, please replace any assignments of the type

      # Old. Bad. Down with this sort of thing.
      HttpLog.options[:foo] = 'bar'  

  with the new configuration block syntax, e.g.

      # Shiny. New. Ruby-ish.
      HttpLog.configure do |config|
        config.foo = 'bar'
      end

  Please see the [README](README.md#configuration) for details. **The old syntax will be dropped in version 1.0.0** (which will be the next version bump) and will raise a deprecation warning until then.

* Dropped support for typhoeus

  That only means typhoeus is no longer explictly tested; it will probably still work, depending on which adapter is used. With the default ethon adapter, the status code will probably not be logged, and there may be other issues. Typhoeus has its own logging facility, so it's just not worth the headache of trying to stay compatible.

* Dropped support for log4r.

  Log4r seems to be no longer maintained for some years; it was causing issues with ruby 2.4, so I dropped it.

* Rounding benchmarks to microseconds. Because anything more is just silly.

* Support for ruby 2.4
* Support for latest versions of all remaining adapters

## 0.3.3 - 2016-11-28

* optional prefix for request data

## 0.3.2 - 2016-04-13

* support for httpclient 2.7

## 0.3.1 - 2016-04-06

* support for latest version of `httprb`

## 0.3.0 - 2016-01-15
* changes
  * binary data is no longer written to the log
* bug fixes
  * consistently forcing encoding of response body to UTF-8
  * considering `charset` part of `Content-Type` header when encoding
  * inspecting 'Content-Encoding' header for gzip decompression in all adapters
