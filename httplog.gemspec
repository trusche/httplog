# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.

$:.push File.expand_path("../lib", __FILE__)
require "httplog/version"

Gem::Specification.new do |s|
  s.name        = "httplog"
  s.version     = HttpLog::VERSION
  s.authors     = ["Thilo Rusche"]
  s.summary     = %q{Logs outgoing Net::HTTP requests.}
  s.homepage    = %q{http://github.com/trusche/httplog}
  s.description = %q{Log outgoing HTTP requests made from your application. Helpful for tracking API calls
                     of third party gems that don't provide their own log output.}
  s.email       = %q{thilorusche@gmail.com}
                     
  s.files       = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  
  s.add_development_dependency "rspec"
  s.add_development_dependency "fakeweb"
end
