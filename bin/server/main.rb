#!/usr/bin/ruby
# A motel server executable
# Executable to use the motel library to track locations in
# real time and provide network access to read/write location data.
#
# Flags:
#  -h --help
#  -s --schema
#  -d --db-config
#
# make sure to specify schema/db config or
# set MOTEL_DB_CONFIG and MOTEL_SCHEMA_FILE
# in the ENV before running this
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

CURRENT_DIR=File.dirname(__FILE__)
#$: << File.expand_path(CURRENT_DIR + "/../../lib")

require 'rubygems'
require 'optparse'
require 'motel'

include Motel
include Motel::Models

######################


def main()
  schema_file = db_conf = nil

  # setup cmd line options
  opts = OptionParser.new do |opts|
    opts.on("-h", "--help", "Print help message") do
       puts opts
       exit
    end
    opts.on("-s", "--schema [path]", "Motel Schema File") do |path|
       schema_file = path
    end
    opts.on("-d", "--db-conf [path]", "Motel DB Conf File") do |path|
       db_conf = path
    end
  end

  # parse cmd line
  begin
    opts.parse!(ARGV)
  rescue OptionParser::InvalidOption
    puts opts
    exit
  end

  schema_file = ENV['MOTEL_SCHEMA_FILE'] if schema_file.nil?
  db_conf     = ENV['MOTEL_DB_CONF']     if db_conf.nil?
  if schema_file.nil? || db_conf.nil?
    puts "both schema and db config needed"
    exit
  end

  Conf.setup(:schema_file => schema_file,
             :db_conf     => db_conf,
             :env         => "production",
             :log_level   => ::Logger::FATAL) # FATAL ERROR WARN INFO DEBUG

  server = Server.new :schema_file => Conf.schema_file
  server.join
end

main()
