Gem::Specification.new do |s|
  s.name        = 'sensu-handler-decommission'
  s.version     = '0.0.1'
  s.date        = '2015-07-07'
  s.summary     = "Decommissions nodes in chef and sensu"
  s.description = "Performs simple steps to check nodes status in aws and delete nodes"
  s.authors     = ["Will Salt"]
  s.email       = 'williamejsalt@gmail.com'
  s.files       = ["lib/decommission.rb"]
  s.homepage    =
    'http://rubygems.org/gems/sensu-handler-decommission'
  s.license       = 'MIT'
end