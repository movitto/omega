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

def main()
    # command line parameters
    schema_file = nil
    location = {:parent_id => nil,
                :x => nil,
                :y => nil,
                :z => nil}
    other_location_id = nil
    movement_strategy_type = nil
    movement_strategy = { :step_delay => nil,
                          :speed => nil,
                          :direction_vector_x => nil,
                          :direction_vector_y => nil,
                          :direction_vector_z => nil,
                          :relative_to => nil,
                          :eccentricity => nil,
                          :semi_latus_rectum => nil,
                          :direction_major_x => nil,
                          :direction_major_y => nil,
                          :direction_major_z => nil,
                          :direction_minor_x => nil,
                          :direction_minor_y => nil,
                          :direction_minor_z => nil}
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
      opts.on("-m", "--subscribe-to-movement", "subscribe to movement updates to location specified by id")do
        request_target = :subscribe_to_location_movement
      end
      opts.on("-r", "--subscribe-to-proximity", "subscribe to locations proximity events")do
        request_target = :subscribe_to_locations_proximity
      end

      opts.separator ""
      opts.separator "Location Options:"
      opts.on("-i", "--id [location_id]", "Target location id") do |id|
        location[:id] = id
      end
      opts.on("-o", "--other-id [location_id]", "Second location id for actions that require it") do |id|
        other_location_id = id
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

      opts.separator ""
      opts.separator "Movement Strategy Options:"
      opts.on("--movement-strategy-type [type]", "Movement strategy type") do |type|
        movement_strategy_type = type
      end
      opts.on("--step-delay [delay]", "Movement strategy step delay") do |delay|
        movement_strategy[:step_delay] = delay.to_f
      end
      opts.on("--speed [speed]", "Movement strategy speed") do |speed|
        movement_strategy[:speed] = speed.to_f
      end
      opts.on("--direction-vector-x [x]", "Linear movement strategy direction vector x coordinate") do |x|
        movement_strategy[:direction_vector_x] = x.to_f
      end
      opts.on("--direction-vector-y [y]", "Linear movement strategy direction vector y coordinate") do |y|
        movement_strategy[:direction_vector_y] = y.to_f
      end
      opts.on("--direction-vector-z [z]", "Linear movement strategy direction vector z coordinate") do |z|
        movement_strategy[:direction_vector_z] = z.to_f
      end
      opts.on("--relative-to [relative]", "Elliptical movement strategy relative to") do |relative|
        movement_strategy[:relative_to] = relative
      end
      opts.on("--eccentricity [e]", "Elliptical movement strategy eccentricity") do |e|
        movement_strategy[:eccentricity] = e
      end
      opts.on("--semi-latus-rectum [l]", "Elliptical movement strategy semi-latus-rectum") do |l|
        movement_strategy[:semi_latus_rectum] = l
      end
      opts.on("--direction-major-x [x]", "Elliptical movement strategy major direction vector x coordinate") do |x|
        movement_strategy[:direction_major_x] = x.to_f
      end
      opts.on("--direction-major-y [y]", "Elliptical movement strategy major direction vector y coordinate") do |y|
        movement_strategy[:direction_major_y] = y.to_f
      end
      opts.on("--direction-major-z [z]", "Elliptical movement strategy major direction vector z coordinate") do |z|
        movement_strategy[:direction_major_z] = z.to_f
      end
      opts.on("--direction-minor-x [x]", "Elliptical movement strategy minor direction vector x coordinate") do |x|
        movement_strategy[:direction_minor_x] = x.to_f
      end
      opts.on("--direction-minor-y [y]", "Elliptical movement strategy minor direction vector y coordinate") do |y|
        movement_strategy[:direction_minor_y] = y.to_f
      end
      opts.on("--direction-minor-z [z]", "Elliptical movement strategy minor direction vector z coordinate") do |z|
        movement_strategy[:direction_minor_z] = z.to_f
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

    if request_target.nil? || location[:id].nil? || schema_file.nil? #||
       #request_target == :update && location[:x].nil? && location[:y].nil? && location[:z].nil? && location[:parent_id].nil?
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

    unless movement_strategy_type.nil?
      movement_strategy = movement_strategy_type.camelize.constantize.new movement_strategy
      location.movement_strategy = movement_strategy
    end

    args = []
    case(request_target)
    when :get_location
      args.push location.id
    when :create_location
      args.push location.id
    when :update_location
      args.push location
    when :subscribe_to_location_movement
      args.push location.id
    when :subscribe_to_locations_proximity
      args.push location.id, other_location_id
    end

    # FIXME need configurable amqp broker ip/port
    client = Motel::Client.new :schema_file => schema_file
    result = client.request request_target, *args

    if request_target == :subscribe_to_location_movement
      client.on_location_moved = lambda { |loc|
         puts "location moved:"
         puts "#{loc}"
      }
      client.join

    elsif request_target == :subscribe_to_locations_proximity
      client.on_locations_proximity = lambda { |loc1, loc2|
         puts "locations proximity:"
         puts "#{loc1}/#{loc2}"
      }
      client.join
    end

    puts "server returned #{result}"
end

main()
