#!/usr/bin/ruby
# A motel server executable
# Executable to use the motel library to track locations in 
# real time and provide network access to read/write location data.
#
# Flags:
#  -h --help 
#
# make sure to set MOTEL_DB_CONFIG and MOTEL_AMQP_CONFIG 
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
  # setup cmd line options
  opts = OptionParser.new do |opts|
    opts.on("-h", "--help", "Print help message") do
       puts opts
       exit
    end
  end

  # parse cmd line
  begin
    opts.parse!(ARGV)
  rescue OptionParser::InvalidOption
    puts opts
    exit
  end

  server = Server.new
  server.join
end

main()
