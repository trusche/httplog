# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.

$:.push File.expand_path("../lib", __FILE__)
require "httplog/version"

Gem::Specification.new do |s|
  s.name        = "httplog"
  s.version     = HttpLog::VERSION
  s.authors     = ["Thilo Rusche"]
  s.summary     = %q{Logs outgoing HTTP requests.}
  s.homepage    = %q{http://github.com/trusche/httplog}
  s.description = %q{Log outgoing HTTP requests made from your application. Helpful for tracking API calls
                     of third party gems that don't provide their own log output.}
  s.email       = %q{thilorusche@gmail.com}

  s.files       = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_development_dependency "rspec"
  s.add_development_dependency "rack"
  s.add_development_dependency "thin"
  s.add_development_dependency "httpclient"
  s.add_development_dependency "httparty"
  s.add_development_dependency "faraday"
  s.add_development_dependency "excon", [">= 0.18.0"]
  s.add_development_dependency "typhoeus"
  s.add_development_dependency "ethon"
  s.add_development_dependency "patron"
  s.add_development_dependency "simplecov"
end
