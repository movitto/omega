# motel project Rakefile
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

#task :default => :test

task :environment do
  require 'lib/motel/conf'
  Motel::Conf.setup(:db_conf       => File.dirname(__FILE__) + '/conf/database.yml',
                    :db_migrations => File.dirname(__FILE__) + '/db/migrate/',
                    :schema_file   => File.dirname(__FILE__) + '/conf/motel-schema.xml')
end

task :test_environment do
   require 'lib/motel/conf'
   Motel::Conf.setup(:db_conf       => File.dirname(__FILE__) + '/conf/database.yml',
                    :db_migrations => File.dirname(__FILE__) + '/db/migrate/',
                    :schema_file   => File.dirname(__FILE__) + '/conf/motel-schema.xml',
                    :env               => "test")
end

namespace :db do
  task(:migrate => :environment) do
    desc "Migrate the database"
    Motel::Conf.migrate_db
  end

  task(:rollback => :environment) do
    desc "Rollback the database"
    Motel::Conf.rollback_db
  end
end

task(:test => :test_environment) do
   desc "Run tests"
   Motel::Conf.migrate_db
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
  system "mkdir ruby-motel-0.2.0 && \
          cp -R conf/ bin/ db/ lib/ test/ ruby-motel-0.2.0/ && \
          tar czvf motel.tgz ruby-motel-0.2.0 && \
          rm -rf ruby-motel-0.2.0"
end
