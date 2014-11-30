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

###
# Parse CLI

def config
  @config ||= OpenStruct.new(:ids       => [],
                             :labels    => [],
                             :url       => 'jsonrpc://localhost:8181',
                             :gnuplot   => '/usr/bin/gnuplot',
                             :delay     => 5,
                             :quit      => false,
                             :locations => {})
end

def verify_params!
  return if File.executable?(config.gnuplot)

  puts "#{config.gnuplot} must be an executable file"
  exit 1
end

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
verify_params!

###
# Retrieve IDs

def node
  @node ||= RJR::Nodes::TCP.new :node_id => 'omega-movement-plotter'
end

def get_ids
  node.invoke(config.url, 'motel::get_locations')
      .collect { |loc| loc.id }
end

def verify_ids!
  return unless config.ids.empty?

  puts "Error no id's found / specified"
  exit 1
end

config.ids = get_ids if config.ids.empty?
verify_ids!

###
# Refresh locations

def get_loc(id)
  node.invoke(config.url, 'motel::get_location', 'with_id', id)
end

def loc_files(id)
  {:coordinates_file => Tempfile.new("coordinates-#{id}"),
   :orientation_file => Tempfile.new("orientation-#{id}")}
end

def init_loc(id)
  config.locations[id] ||= loc_files(id)
end

def coords_file(id)
  config.locations[id][:coordinates_file]
end

def orientation_file(id)
  config.locations[id][:orientation_file]
end

def coords_output(loc)
  "#{loc.x} #{loc.y} #{loc.z}\n"
end

def orient_title(loc)
  "#{loc.orx.round_to(2)},#{loc.ory.round_to(2)},#{loc.orz.round_to(2)}"
end

def orientation_output(loc)
  "#{loc.orx} #{loc.ory} #{loc.orz} #{orient_title(loc)}\n"
end

def write_coords(loc)
  f = coords_file(loc.id)
  f.write coords_output(loc)
  f.flush
end

def write_orientation(loc)
  f = orientation_file(loc.id)
  f.write orientation_output(loc)
  f.flush
end

def write_loc(loc)
  write_coords(loc)
  write_orientation(loc)
end

def init_extrema(loc)
  config.max = Array.new(loc.coordinates)
  config.min = Array.new(config.max)
end

def update_extrema(loc)
  config.max[0] = loc.x if loc.x > config.max[0]
  config.max[1] = loc.y if loc.y > config.max[1]
  config.max[2] = loc.z if loc.z > config.max[2]

  config.min[0] = loc.x if loc.x < config.min[0]
  config.min[1] = loc.y if loc.y < config.min[1]
  config.min[2] = loc.z if loc.z < config.min[2]
end

def create_range
  xrange = config.min[0] == config.max[0]
  yrange = config.min[1] == config.max[1]
  zrange = config.min[2] == config.max[2]

  scale  = 5
  xmin   = config.min[0] - config.min[0] / scale
  xmax   = config.min[0] + config.min[0] / scale
  ymin   = config.min[1] - config.min[1] / scale
  ymax   = config.min[1] + config.min[1] / scale
  zmin   = config.min[2] - config.min[2] / scale
  zmax   = config.min[2] + config.min[2] / scale

  config.min[0], config.max[0] = xmin, xmax if xrange
  config.min[1], config.max[1] = ymin, ymax if yrange
  config.min[2], config.max[2] = zmin, zmax if zrange
end

def refresh_locations
  config.ids.each do |id|
    loc   = get_loc(id)
    first = config.locations.empty?
    init_loc(id)
    write_loc(loc)

    first ? init_extrema(loc) : update_extrema(loc)
    config.first_location = first
  end

  # if min == max, create range
  create_range
end

###
# Plot Locations

def plot_title(id)
  id[0...15]
end

def coord_plot_str(id)
  "'#{coords_file(id).path}' title '#{plot_title(id)}'"
end

def orient_plot_str(id)
  "'#{orientation_file(id).path}' title '#{plot_title(id)}', '' using 1:2:3:4 with labels notitle"
end

def coord_plots
  config.ids.collect { |id| coord_plot_str(id) }
end

def orient_plots
  config.ids.collect { |id| orient_plot_str(id) }
end

def pipe(str)
  config.io.puts str
end

def multiplot_header
  "set multiplot layout 1,2 title 'Omega Locations'"
end

def coords_title
  "set title 'Coordinates'"
end

def coords_style
  "set style data linespoints"
end

def center_label
  "set label 1 'center' at 0,0,0"
end

def format_label(label, num)
  text, x, y, z = *label
  "set label #{num+1} '#{text}' at #{x},#{y},#{z}"
end

def set_coords_xrange
  "set xrange [#{config.min[0]}:#{config.max[0]}]"
end

def set_coords_yrange
  "set yrange [#{config.min[1]}:#{config.max[1]}]"
end

def set_coords_zrange
  "set zrange [#{config.min[2]}:#{config.max[2]}]"
end

def coords_plot
  "splot #{coord_plots.join(',')}"
end

def plot_coords
  pipe coords_title
  pipe coords_style
  pipe center_label

  config.labels.each_index do |i|
    pipe format_label(config.labels[i], i)
  end

  pipe set_coords_xrange
  pipe set_coords_yrange
  pipe set_coords_zrange
  pipe coords_plot
end

def orientation_title
  "set title 'Orientation'"
end

def orientation_style
  "set style data points"
end

def unset_label(num)
  "unset label #{num}"
end

def set_orientation_xrange
  "set xrange [-1:1]"
end

def set_orientation_yrange
  "set yrange [-1:1]"
end

def set_orientation_zrange
  "set zrange [-1:1]"
end

def orientations_plot
  config.io.puts "splot #{orient_plots.join(',')}"
end

def multiplot_footer
  "unset multiplot"
end

def plot_orientation
  pipe orientation_title
  pipe orientation_style

  1.upto(config.labels.size) { |i| pipe unset_label(i) }

  pipe set_orientation_xrange
  pipe set_orientation_yrange
  pipe set_orientation_zrange
  pipe orientations_plot
end

def plot_locations
  return if config.first_location # skip first location as axis range won't be valid
  pipe "set term x11"
  pipe multiplot_header
  plot_coords
  plot_orientation
  pipe multiplot_footer
end

###
# Launch GNUPlot

def trap_int
  trap("INT") do
    puts "Exiting"
    exit 0
  end
end

def main
  refresh_locations
  plot_locations
end

def run_loop
  until config.quit
    main
    sleep config.delay
  end
end

def open_pipe
  IO.popen([config.gnuplot, '-noraise'], 'w') do |io|
    config.io = io
    run_loop
  end
end

trap_int
open_pipe
