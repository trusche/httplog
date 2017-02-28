## 1.0.0 - 2017-02-28

* **BREAKING CHANGE:** grown-up configuration

  If you're using any custom configuration, please replace any assignments of the type `HttpLog.options[:foo] = 'bar'`  with the new configuration block syntax, e.g. 

      HttpLog.configure do |config|
        config.foo = 'bar'
      end

  Please see the [README](README.md#configuration) for details.

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
