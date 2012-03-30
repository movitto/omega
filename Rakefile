# motel project Rakefile
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rdoc/task'
require "rspec/core/rake_task"
require 'rubygems/package_task'


GEM_NAME="motel"
PKG_VERSION='0.3.1'
SIMRPC_SPEC='conf/motel-schema.xml'

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace', '-fd', '-c']
end

Rake::RDocTask.new do |rd|
    rd.main = "README.rdoc"
    rd.rdoc_dir = "doc/site/api"
    rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

PKG_FILES = FileList['conf/motel-schema.xml', 'lib/**/*.rb', 
  'COPYING', 'LICENSE', 'Rakefile', 'README.rdoc', 'spec/**/*.rb' ]

SPEC = Gem::Specification.new do |s|
    s.name = GEM_NAME
    s.version = PKG_VERSION
    s.files = PKG_FILES
    s.executables << 'motel-server' << 'motel-client' << 'motel-rage-client'

    s.required_ruby_version = '>= 1.8.1'
    s.required_rubygems_version = Gem::Requirement.new(">= 1.3.3")
    s.add_development_dependency('rspec', '~> 1.3.0')

    s.author = "Mohammed Morsi"
    s.email = "movitto@yahoo.com"
    s.date = %q{2010-09-05}
    s.description = %q{Motel is a library to track and move the locations of objects in a 3D environment.}
    s.summary = %q{Motel is a library to track and move the locations of objects in a 3D environment.}
    s.homepage = %q{http://morsi.org/projects/motel}
end

Gem::PackageTask.new(SPEC) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
end
