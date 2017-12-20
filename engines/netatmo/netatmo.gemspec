$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "netatmo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "netatmo"
  s.version     = Netatmo::VERSION
  s.authors     = ["Marco Roth"]
  s.email       = ["marco.roth@intergga.ch"]
  s.homepage    = "http://google.com"
  s.summary     = "Summary of Netatmo."
  s.description = "Description of Netatmo."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.4"

  s.add_development_dependency "sqlite3"
end
