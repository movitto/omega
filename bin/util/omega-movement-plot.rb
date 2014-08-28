#!/usr/bin/ruby
# Utility using gnuplot + omega client to plot location's movement in real time
#
# Note requires the 'gnuplot' utility to be seperately installed, we do not
# use the 'gnuplot' gem (so as to be able to refresh plot).
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'ostruct'
require 'tempfile'
require 'optparse'

require 'omega'
require 'rjr/nodes/tcp'

config           = OpenStruct.new
config.ids       = []
config.labels    = []
config.url       = 'jsonrpc://localhost:8181'
config.gnuplot   = '/usr/bin/gnuplot'
config.delay     = 5

config.quit      = false
config.locations = {}

optparse = OptionParser.new do |opts|
  opts.on('-h', '--help', 'Display this help screen') do
    puts opts
    exit
  end

  opts.on('-g', '--gnuplot path', 'path to the gnuplot binary') do |p|
    config.gnuplot = p
  end

  opts.on('-u', '--url url', 'url of omega-server') do |u|
    config.url = u
  end

  opts.on('-i', '--id id', 'location id to track, may be specified multiple times or omitted') do |i|
    config.ids << i
  end

  opts.on('-d', '--delay seconds', 'delay between location polls') do |d|
    config.delay = d.to_i
  end

  opts.on('-l', '--label label,x,y,z', 'add specified label at specified coordinates') do |label|
    config.labels << label.split(',')
  end

  # TODO options to toggle graphs, manually set axis' ranges, max points retained, etc
end

optparse.parse!

unless File.executable?(config.gnuplot)
  puts "#{config.gnuplot} must be an executable file"
  exit 1
end

config.node = RJR::Nodes::TCP.new :node_id => 'omega-movement-plotter'

if config.ids.size == 0
  locations = config.node.invoke(config.url, 'motel::get_locations')
  config.ids = locations.collect { |loc| loc.id }
end

if config.ids.size == 0
  puts "Error no id's found / specified"
  exit 1
end

def refresh_locations(config)
  config.ids.each do |id|
    location = config.node.invoke(config.url, 'motel::get_location', 'with_id', id)

    config.first_location = config.locations.empty?
    config.locations[id] ||= {:coordinates_file => Tempfile.new("coordinates-#{id}"),
                              :orientation_file => Tempfile.new("orientation-#{id}")}

    coordinates_output = "#{location.x} #{location.y} #{location.z}\n"
    orientation_title  = "#{location.orx.round_to(2)},#{location.ory.round_to(2)},#{location.orz.round_to(2)}"
    orientation_output = "#{location.orx} #{location.ory} #{location.orz} #{orientation_title}\n"
    config.locations[id][:coordinates_file].write coordinates_output
    config.locations[id][:orientation_file].write orientation_output
    config.locations[id][:coordinates_file].flush
    config.locations[id][:orientation_file].flush

    if config.first_location
      config.max = Array.new(location.coordinates)
      config.min = Array.new(config.max)

    else
      config.max[0] = location.x if location.x > config.max[0]
      config.max[1] = location.y if location.y > config.max[1]
      config.max[2] = location.z if location.z > config.max[2]

      config.min[0] = location.x if location.x < config.min[0]
      config.min[1] = location.y if location.y < config.min[1]
      config.min[2] = location.z if location.z < config.min[2]
    end
  end
end

def plot_locations(config)
  return if config.first_location # skip first location as axis range won't be valid
  config.io.puts "set term x11"

  coord_plots  = []
  orient_plots = []
  config.ids.each do |id|
    title = id[0...15]
    coord_plots  << "'#{config.locations[id][:coordinates_file].path}' title '#{title}'"
    orient_plots << "'#{config.locations[id][:orientation_file].path}' title '#{title}', '' using 1:2:3:4 with labels notitle"
  end

  config.io.puts "set multiplot layout 1,2 title 'Omega Locations'"

  config.io.puts "set title 'Coordinates'"
  config.io.puts "set style data linespoints"

  config.io.puts "set label 1 'center' at 0,0,0"
  config.labels.each_index do |i|
    label, x, y, z = *config.labels[i]
    config.io.puts "set label #{i+1} '#{label}' at #{x},#{y},#{z}"
  end

  config.io.puts "set xrange [#{config.min[0]}:#{config.max[0]}]"
  config.io.puts "set yrange [#{config.min[1]}:#{config.max[1]}]"
  config.io.puts "set zrange [#{config.min[2]}:#{config.max[2]}]"
  config.io.puts "splot #{coord_plots.join(',')}"

  config.io.puts "set title 'Orientation'"
  config.io.puts "set style data points"

  1.upto(config.labels.size) { |i| config.io.puts "unset label #{i}" }

  config.io.puts "set xrange [-1:1]"
  config.io.puts "set yrange [-1:1]"
  config.io.puts "set zrange [-1:1]"
  config.io.puts "splot #{orient_plots.join(',')}"

  config.io.puts "unset multiplot"
end

IO.popen([config.gnuplot, '-noraise'], 'w') do |io|
  config.io = io

  until config.quit
    refresh_locations config
    plot_locations    config
    sleep config.delay
  end
end
