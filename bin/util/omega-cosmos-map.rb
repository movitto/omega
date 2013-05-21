#!/usr/bin/ruby
# graphs a universe defined using the Omega DSL
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO should employ a ruby parser or other mechanism (graphing backend to
# dsl, retrieving heirarchies from server, etc) instead of simple regex's

require 'rgl/adjacency'
require 'rgl/dot'

UNIVERSE = ARGV.shift || "examples/universes/complete.rb"

$current_graph = current_galaxy = current_system = 
current_star = current_planet = current_moon = nil

graphs = {}
$galaxy_systems = []
$galaxy_gates   = []

def graph_galaxy
  $galaxy_gates.each { |systems|
    $galaxy_systems.delete(systems[0])
    $current_graph.add_vertex(systems[0])
    $current_graph.add_vertex(systems[1])
    $current_graph.add_edge(systems[0], systems[1])
  }

  $galaxy_systems.each { |system|
    $current_graph.add_vertex(system)
  }
end

inf = File.open(UNIVERSE)
inf.each_line { |l|
  if l =~ /\s*galaxy '(.*)'.*/
    graph_galaxy unless $current_graph.nil?

    current_galaxy = $1
    $galaxy_gates   = []
    $galaxy_systems = []
    $current_graph = RGL::DirectedAdjacencyGraph.new
    graphs[current_galaxy] = $current_graph

  elsif l =~ /\s*system '(.*)', '(.*)'.*/
    current_system = $1
    current_star = $2
    $galaxy_systems << current_system

  elsif l =~ /\s*planet '(.*)'.*/
    current_planet = $1

  elsif l =~ /\s*moon '(.*)'.*/
    current_moon = $1

  elsif l =~ /\s*jump_gate\s*system\('(.*)'\),\s*system\('(.*)'\).*/
    $galaxy_gates << [$1, $2]
  end
}

graph_galaxy # need to run one final time for last galaxy

graphs.each { |n,g| g.write_to_graphic_file("png", "doc/graphs/#{n}")}
