#!/usr/bin/ruby
# A simple motel client executable
# Executable to use the motel library to perform operations on
# a remote location server, simply printing out results
#
# Flags: (see below)
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../../../lib")

require 'rubygems'
require 'optparse'
require 'motel'

include Motel
include Motel::MovementStrategies

######################

# TODO movement strategy support

def main()
    # command line parameters
    schema_file = nil
    location = {:parent_id => nil,
                :x => nil,
                :y => nil,
                :z => nil}
    request_target = nil

    # setup cmd line options
    opts = OptionParser.new do |opts|
      opts.banner = "Usage: main.rb [command] [options]"

      opts.on("-h", "--help", "Print this help message") do
         puts opts
         exit
      end

      opts.on("-s", "--schema [path]", "Motel Schema File") do |path|
         schema_file = path
      end

      opts.separator ""
      opts.separator "Commands:"
      opts.on("-g", "--get", "get location specified by id")do
        request_target = :get_location
      end
      opts.on("-c", "--create", "create location w/ id")do
        request_target = :create_location
      end
      opts.on("-u", "--update", "update location specified by id w/ specified options")do
        request_target = :update_location
      end
      opts.on("-b", "--subscribe", "subscribe to updates to location specified by id")do
        request_target = :subscribe_to_location
      end

      opts.separator ""
      opts.separator "Options:"
      opts.on("-i", "--id [location_id]", "Target location id") do |id|
        location[:id] = id
      end
      opts.on("-p", "--parent-id [location_id]", "Target parent location id") do |id|
        location[:parent_id] = id
      end
      opts.on("-x", "--xcoordinate [coordinate]", "Target location x coordinate") do |x|
        location[:x] = x
      end
      opts.on("-y", "--ycoordinate [coordinate]", "Target location y coordinate") do |y|
        location[:y] = y
      end
      opts.on("-z", "--zcoordinate [coordinate]", "Target location z coordinate") do |z|
        location[:z] = z
      end

    end

    # parse cmd line
    begin
      opts.parse!(ARGV)
    rescue OptionParser::InvalidOption => e
      puts opts
      puts e.to_s
      exit
    end

    if request_target.nil? || location[:id].nil? || schema_file.nil? ||
       request_target == :update && location[:x].nil? && location[:y].nil? && location[:z].nil? && location[:parent_id].nil?
         puts opts
         puts "must specify schema, a command to perform, a location id, and other required options"
         exit
    end

    lid = location[:id]
    location = Motel::Location.new :id => location[:id],
                                   :parent_id => location[:parent_id],
                                   :x => location[:x],
                                   :y => location[:y],
                                   :z => location[:z]
    args = []
    case(request_target)
    when :get_location
      args.push location.id
    when :create_location
      args.push location.id
    when :update_location
      args.push location
    when :subscribe_to_location
      args.push location.id
    end

    # FIXME need configurable amqp broker ip/port
    client = Motel::Client.new :schema_file => schema_file
    result = client.request request_target, *args

    if request_target == :subscribe_to_location
      client.on_location_received = lambda { |loc|
         puts "location received:"
         puts "#{loc}"
      }
      client.join
    end

    puts "server returned #{result}"
end

main()
