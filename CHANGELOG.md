## 0.3.1 - 2016-04-13

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