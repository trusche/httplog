# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "httplog"
  s.summary = "Logs outgoing Net::HTTP requests."
  s.description = "Log outgoing HTTP requests made from your application. Helpful for tracking API calls of third party gems that don't provide their own log output."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  
  s.add_development_dependency "rspec"
end
