# setup necessary environment boilerplate code
#
# grab MOTEL_ENV, MOTEL_DB_CONF, and MOTEL_LOG_LEVEL from the environment
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

### include the 'lib' directory
$: << File.expand_path(File.dirname(__FILE__) + '/..')

### default environment if not set
ENV['MOTEL_ENV'] = "production" if ENV['MOTEL_ENV'].nil?

### setup active record
require 'rubygems'
require 'active_record'
dbconfig = YAML::load(File.open(ENV['MOTEL_DB_CONF']))  
ActiveRecord::Base.establish_connection(dbconfig[ENV['MOTEL_ENV']])  

### setup the logger
require 'logger'
# see http://osdir.com/ml/lang.ruby.rails.core/2007-01/msg00082.html
class Logger
  def format_message(severity, timestamp, progname, msg)
    "#{severity} #{timestamp} (#{$$}) #{msg}\n"
  end
end
$logger = Logger.new(STDOUT)
$logger.level = ENV['MOTEL_LOG_LEVEL'].nil? ? Logger::WARN : ENV['MOTEL_LOG_LEVEL'] # FATAL ERROR WARN INFO DEBUG
