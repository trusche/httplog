# Provide a simple gemspec so you can easily use your
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "httplog"
  s.summary = "Logs outgoing Net::HTTP requests."
  s.description = "Find out what those third party API gems are up to."
  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.version = "0.0.2"
end
