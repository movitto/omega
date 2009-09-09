# motel project Rakefile
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

#task :default => :test

task :environment do
  ENV['MOTEL_DB_CONF']   ||= File.dirname(__FILE__) + '/conf/database.yml'
  ENV['MOTEL_AMQP_CONF'] ||= File.dirname(__FILE__) + '/conf/amqp.yml'
  require 'lib/motel/environment'
end

namespace :db do
  desc "Migrate the database"

  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end

  task(:rollback => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.rollback("db/migrate")
  end
end

task(:test_env) do
   desc "Set Test Environment"
   ENV['MOTEL_ENV']="test"
end

task(:test => [:test_env, :environment]) do
   desc "Run tests"
   require 'test/all_tests'
end

task :rdoc do  
  desc "Create RDoc documentation"  
  system "rdoc --title 'Motel documentation' lib/"  
end  

task :create_gem do
  desc "Create a new gem"
  system "gem build motel.gemspec"
end

task :dist do
  desc "Create a source tarball"
  system "mkdir ruby-motel-0.1.0 && \
          cp -R conf/ bin/ db/ lib/ test/ ruby-motel-0.1.0/ && \
          tar czvf motel.tgz ruby-motel-0.1.0 && \
          rm -rf ruby-motel-0.1.0"
end
