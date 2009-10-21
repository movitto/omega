# load / setup the config / environment 
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

# include logger dependencies
require 'logger'

# include active record dependencies
require 'rubygems'
require 'active_record'

### include the 'lib' directory
$: << File.expand_path(File.dirname(__FILE__) + '/..')

# see http://osdir.com/ml/lang.ruby.rails.core/2007-01/msg00082.html
class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{severity} #{timestamp} (#{$$}) #{msg}\n"
  end
end

module Motel

# setup various motel config
class Conf

   def self.setup(args)
      @@schema = args[:schema]           if args.has_key? :schema
      @@schema_file = args[:schema_file] if args.has_key? :schema_file
      @@env = args[:env]                 if args.has_key? :env
      @@log_level = args[:log_level]     if args.has_key? :log_level
      @@db_conf = args[:db_conf]         if args.has_key? :db_conf

      @@env       = "production" if @@env.nil?
      @@log_level = ::Logger::FATAL unless defined? @@log_level  # FATAL ERROR WARN INFO DEBUG

      unless @@db_conf.nil?
         # setup active record
         dbconfig = YAML::load(File.open(@@db_conf))  
         ActiveRecord::Base.establish_connection(dbconfig[@@env])  
      end
   end

   def self.schema
      @@schema if defined? @@schema
   end

   def self.schema_file
      @@schema_file if defined? @@schema_file
   end

   def self.log_level
     @@log_level if defined? @@log_level
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
end

end # module Motel


