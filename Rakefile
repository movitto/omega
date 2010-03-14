# motel project Rakefile
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'rake/gempackagetask'


GEM_NAME="motel"
PKG_VERSION='0.3'
SIMRPC_SPEC='conf/motel-schema.xml'

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end

Rake::RDocTask.new do |rd|
    rd.main = "README.rdoc"
    rd.rdoc_dir = "doc/site/api"
    rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

PKG_FILES = FileList['bin/**/*', 'conf/motel-schema.xml', 'lib/**/*.rb', 
  'COPYING', 'LICENSE', 'Rakefile', 'README.rdoc', 'spec/**/*.rb' ]

SPEC = Gem::Specification.new do |s|
    s.name = GEM_NAME
    s.version = PKG_VERSION
    s.files = PKG_FILES

    s.required_ruby_version = '>= 1.8.1'
    s.required_rubygems_version = Gem::Requirement.new(">= 1.3.3")

    s.author = "Mohammed Morsi"
    s.email = "movitto@yahoo.com"
    s.date = %q{2010-03-14}
    s.description = %q{Motel is a library to track and move the locations of objects in a 3D environment.}
    s.summary = %q{Motel is a library to track and move the locations of objects in a 3D environment.}
    s.homepage = %q{http://morsi.org/projects/motel}
end

Rake::GemPackageTask.new(SPEC) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
end
