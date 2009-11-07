# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{motel}
  s.version = "0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.1")
  s.author = "Mohammed Morsi"
  s.date = %q{2009-09-04}
  s.description = %q{Motel is a library to track and move the locations of objects in a 3D environment.}
  s.summary     = %q{Motel is a library to track and move the locations of objects in a 3D environment.}
  s.email = %q{movitto@yahoo.com}
  s.extra_rdoc_files = [ "README", ]
  s.files = [ "conf/amqp.yml", "conf/database.yml", 
              "db/migrate/001_create_locations_and_movement_strategies.rb",
              "db/migrate/002_create_linear_movement_strategy.rb",
              "db/migrate/003_create_elliptical_movement_strategy.rb",
              "lib/motel", "lib/motel/models", "lib/motel/models/location.rb", "lib/motel/models/movement_strategy.rb",
              "lib/motel/models/stopped.rb", "lib/motel/models/linear.rb", "lib/motel/models/elliptical.rb",
              "lib/motel/common.rb", "lib/motel/environment.rb", "lib/motel/loader.rb", "lib/motel/messages.rb", 
              "lib/motel/network.rb", "lib/motel/qpid.rb", "lib/motel/runner.rb", "lib/motel/semaphore.rb", "lib/motel.rb", 
              "LICENSE", "COPYING" ]
  s.has_rdoc = true
  s.homepage = %q{http://morsi.org/projects/motel}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', ">= 2.1.1"
  #s.add_dependency 'qpid', ">= 2.1.1"
  #s.add_runtime_dependency "", ""
end
