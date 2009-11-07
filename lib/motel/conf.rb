# load / setup the config / environment 
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

# include logger dependencies
require 'logger'

# include active record dependencies
require 'rubygems'
require 'active_record'

# activerecord hack
# http://www.nabble.com/quote_ident-td24684969.html
require 'active_record/connection_adapters/postgresql_adapter'
def PGconn.quote_ident(name)
    %("#{name}")
end

### include the 'lib' directory
$: << File.expand_path(File.dirname(__FILE__) + '/..')

# activerecord hack
# see http://osdir.com/ml/lang.ruby.rails.core/2007-01/msg00082.html
class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{severity} #{timestamp} (#{$$}) #{msg}\n"
  end
end

module Motel

# setup various motel config
class Conf

   # 'setup' static class method should be invoked before performing any motel
   # operations. Will set various configuration fields to values passed in or to
   # their default values, providing subsequent access by the motel library. Connects
   # to db database specified by db_conf / env.
   def self.setup(args)
      @@schema = args[:schema]               if args.has_key? :schema
      @@schema_file = args[:schema_file]     if args.has_key? :schema_file
      @@env = args[:env]                     if args.has_key? :env
      @@log_level = args[:log_level]         if args.has_key? :log_level
      @@db_conf = args[:db_conf]             if args.has_key? :db_conf
      @@db_migrations = args[:db_migrations] if args.has_key? :db_migrations

      @@env       = "production" unless defined? @@env
      @@log_level = ::Logger::FATAL unless defined? @@log_level  # FATAL ERROR WARN INFO DEBUG

      unless @@db_conf.nil? || (defined?(@@db_connection_established) && @@db_connection_established)
         # setup active record
         dbconfig = YAML::load(File.open(@@db_conf))  
         ActiveRecord::Base.logger = Motel::Logger.logger
         ActiveRecord::Base.establish_connection(dbconfig[@@env])  
         @@db_connection_established = true
      end
   end

   # disconnect the database
   def self.disconnect_db
     if defined?(@@db_connection_established) && @@db_connection_established
       ActiveRecord::Base.connection.disconnect!
       @@db_connection_established = false
     end
   end

   # return motel schema if defined or nil
   def self.schema
      @@schema if defined? @@schema
   end

   # return motel schema file if defined or nil
   def self.schema_file
      @@schema_file if defined? @@schema_file
   end

   # return log level if defined or nil
   def self.log_level
     @@log_level if defined? @@log_level
   end

   # perform any outstanding motel migrations.
   def self.migrate_db
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Base.logger = Motel::Logger.logger
      ActiveRecord::Migrator.migrate(@@db_migrations)
   end

   # perform a single motel db rollback
   def self.rollback_db
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Base.logger = Motel::Logger.logger
      ActiveRecord::Migrator.rollback(@@db_migrations)
   end
  
end

# Logger helper class
class Logger
  private
    def self._instantiate_logger
       unless defined? @@logger
         @@logger = ::Logger.new(STDOUT)
         @@logger.level = Conf.log_level
       end 
    end 
  public
    def self.method_missing(method_id, *args)
       _instantiate_logger
       @@logger.send(method_id, args)
    end 
    def self.logger
       _instantiate_logger
       @@logger
    end
end

end # module Motel


