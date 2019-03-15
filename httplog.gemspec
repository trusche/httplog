# frozen_string_literal: true

# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'httplog/version'

Gem::Specification.new do |gem|
  gem.name        = 'httplog'
  gem.version     = HttpLog::VERSION
  gem.licenses    = ['MIT']
  gem.summary     = 'Log outgoing HTTP requests.'
  gem.authors     = ['Thilo Rusche']
  gem.email       = 'thilorusche@gmail.com'
  gem.homepage    = 'http://github.com/trusche/httplog'
  gem.description = "Log outgoing HTTP requests made from your application. Helpful for tracking API calls
                     of third party gems that don't provide their own log output."

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.require_paths = ['lib']

  gem.required_ruby_version = '>= 2.2'

  gem.add_development_dependency 'ethon', ['~> 0.11']
  gem.add_development_dependency 'excon', ['~> 0.60']
  gem.add_development_dependency 'faraday', ['~> 0.14']
  gem.add_development_dependency 'guard-rspec', ['~> 4.7']
  gem.add_development_dependency 'http', ['~> 3.0']
  gem.add_development_dependency 'httparty', ['~> 0.16']
  gem.add_development_dependency 'httpclient', ['~> 2.8']
  gem.add_development_dependency 'listen', ['~> 3.0']
  gem.add_development_dependency 'patron', ['~> 0.12']
  gem.add_development_dependency 'rake', ['~> 12.3']
  gem.add_development_dependency 'rspec', ['~> 3.7']
  gem.add_development_dependency 'simplecov', ['~> 0.15']
  gem.add_development_dependency 'thin', ['~> 1.7']

  gem.add_dependency 'rack', ['>= 1.0']
  gem.add_dependency 'rainbow', ['>= 2.0.0']
end
