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
