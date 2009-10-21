#!/usr/bin/ruby
# A simple motel client executable
# Executable to use the motel library to perform operations on
# a remote location server, simply printing out results
#
# Flags: (see below)
#
# make sure to set MOTEL_DB_CONFIG and MOTEL_AMQP_CONFIG
# in the ENV before running this
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

CURRENT_DIR=File.dirname(__FILE__)
#$: << File.expand_path(CURRENT_DIR + "/../../../lib")

require 'rubygems'
require 'optparse'
require 'motel'

include Motel
include Motel::Models

######################


def main()
    # command line parameters
    schema_file = db_conf = nil
    location = {:parent_id => nil,
                :x => nil,
                :y => nil,
                :z => nil}
    movement_strategy_type    = nil
    movement_strategy_encoded = nil
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
      opts.on("-d", "--db-conf [path]", "Motel DB Conf File") do |path|
         db_conf = path
      end

      opts.separator ""
      opts.separator "Commands:"
      opts.on("-g", "--get", "get location specified by id")do
        request_target = :get
      end
      opts.on("-r", "--register", "register location specified by id")do
        request_target = :register
      end
      opts.on("-a", "--save", "save location specified by id")do
        request_target = :save
      end
      opts.on("-u", "--update", "update location specified by id w/ specified options")do
        request_target = :update
      end
      opts.on("-b", "--subscribe", "subscribe to updates to location specified by id")do
        request_target = :subscribe
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
      opts.on("-m", "--movement-strategy [type]", "Target movement strategy type") do |m|
        movement_strategy_type = m
      end
      opts.on("-e", "--strategy-encoded [encoded]", "Encoded movement strategy") do |m|
        movement_strategy_encoded = m
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

    schema_file = ENV['MOTEL_SCHEMA_FILE'] if schema_file.nil?
    db_conf     = ENV['MOTEL_DB_CONF']     if db_conf.nil?

    if request_target.nil? || location[:id].nil? || schema_file.nil? || db_conf.nil? ||
       request_target == :update && location[:x].nil? && location[:y].nil? && location[:z].nil? && location[:parent_id].nil? && movement_strategy_type.nil? && movement_strategy_encoded.nil?
         puts opts
         puts "must specify schema & db configs, a command to perform, a location id, and other required options"
         exit
    end

    Conf.setup(:schema_file => schema_file,
               :db_conf     => db_conf,
               :env         => "production",
               :log_level   => ::Logger::DEBUG) # FATAL ERROR WARN INFO DEBUG


    lid = location[:id]
    location = Location.new :parent_id => location[:parent_id],
                            :x => location[:x],
                            :y => location[:y],
                            :z => location[:z]
    location.id = lid

    client = Client.new
    result = client.request :request_target => request_target,
                            :location => location,
                            :movement_stratgy_type => movement_strategy_type

    if request_target == :subscribe
      client.on_location_received = lambda { |loc|
         puts "location received:"
         puts "#{loc}"
      }
      client.join
    end

    puts "server returned #{result}"
end

main()
