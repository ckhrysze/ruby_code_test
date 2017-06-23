Gem::Specification.new do |s|
  s.name        = "fsl_processor"
  s.version     = "0.1"
  s.authors     = ["Chris Hildebrand"]
  s.email       = ["chris@chrishildebrand.net"]

  s.summary     = "A processor for the fictitious scripting language"
  s.description = "A ruby based processor for the fictitious scripting language"
  
  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = ">= 1.9.2"

  s.add_dependency "json"

  s.add_development_dependency "rspec"
  
  s.files        = Dir.glob("{bin,lib,data,doc}/**/*")
  s.executables  = ['fsl']
  s.require_path = 'lib'
end
