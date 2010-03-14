#!/usr/bin/ruby
# A motel server executable
# Executable to use the motel library to track locations in
# real time and provide network access to read/write location data.
#
# Flags:
#  -h --help
#  -s --simrpc-schema
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../../lib")

require 'rubygems'
require 'optparse'
require 'motel'

include Motel
include Motel::MovementStrategies

######################


def main()
  schema_file = nil

  # setup cmd line options
  opts = OptionParser.new do |opts|
    opts.on("-h", "--help", "Print help message") do
       puts opts
       exit
    end
    opts.on("-s", "--simrpc-schema [path]", "Motel Simrpc Schema File") do |path|
       schema_file = path
    end
  end

  # parse cmd line
  begin
    opts.parse!(ARGV)
  rescue OptionParser::InvalidOption
    puts opts
    exit
  end

  if schema_file.nil? || ! File.exists?(schema_file)
     puts "motel simrpc schema file required"
     exit
  end

  # start location runner
  Motel::Runner.instance.start :async => true

  # start listening for requests / block
  # FIXME need configurable amqp broker ip/port
  server = Motel::Server.new(:schema_file => schema_file).join
end

main()
