# The Location entity
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'
require 'motel/movement_strategy'

module Motel

# Locations are the entity at the center of the Motel subsystem
# and describe a set of x,y,z coordinates in cartesian space.
#
# The location may be related to a parent through its parent_id
# and parent properties, in which case the x,y,z coordinates reference
# the position in and/or relative to its parent.
#
# If no parent_id / parent is specified, the location is often assumed
# to be the 'root' location of its local system. Ultimately though the
# sematics of the location heirarchy is left up to the client.
#
# A location is associated with a instance of a {Motel::MovementStrategy} subclass,
# by default {Motel::MovementStrategies::Stopped}. The movement_strategy#move
# method is invoked by the {Motel::Runner} with the location instance
# on every run cycle.
#
# A location many optionally specify a remote_queue through which children
# will be retreived from (currently via json-rpc over amqp)
class Location

   # ID of location
   attr_accessor :id

   # ID of location's parent
   attr_accessor :parent_id

   # Coordinates relative to location's parent
   attr_accessor :x, :y, :z

   # [Motel::Location] parent location
   attr_accessor :parent

   # [Array<Motel::Location>] child locations
   attr_accessor :children

   # Set location's parent
   #
   # (also sets parent_id accordingly)
   # @param [Motel::Location] new_parent new parent to set on location
   def parent=(new_parent)
     @parent = new_parent
     @parent_id = @parent.id unless @parent.nil?
   end

   # Unit vector corresponding to Orientation of the location
   attr_accessor :orientation_x, :orientation_y, :orientation_z

   # [Motel::MovementStrategy] Movement strategy through which to move location
   attr_accessor :movement_strategy

   # [Array<Motel::MovementCallback>] Callbacks to be invoked on movement
   attr_accessor :movement_callbacks

   # [Array<Motel::RotationCallback>] Callbacks to be invoked on rotation
   attr_accessor :rotation_callbacks

   # [Array<Motel::ProximityCallback>] Callbacks to be invoked on proximity
   attr_accessor :proximity_callbacks

   # TODO [Array<Motel::StrategyCallback>] Callbacks to be invoked when movement strategy is changed

   # [Array<Motel::StoppedCallback>] Callbacks to be invoked on stopped
   attr_accessor :stopped_callbacks

   # Generic association which this location can belong to (not used by motel)
   attr_accessor :entity

   # Boolean flag indicating if permission checks should restrict access to this location
   attr_accessor :restrict_view

   # Boolean flag indicating if permission checks should restrict modification of this location
   attr_accessor :restrict_modify

   # Remote queue which to retrieve child locations from if any (may be nil)
   attr_accessor :remote_queue

  # Location initializer
  # @param [Hash] args hash of options to initialize location with
  # @option args [Integer] :id,'id' id to assign to the location
  # @option args [Integer] :parent_id,'parent_id' parent_id to assign to the location
  # @option args [Motel::Location] :parent,'parent' parent location to assign to the location
  # @option args [Array<Motel::Location>] :children,'children' child locations to assign to the location
  # @option args [Integer,Float] :x,'x' x coodinate of location
  # @option args [Integer,Float] :y,'y' y coodinate of location
  # @option args [Integer,Float] :z,'z' z coodinate of location
  # @option args [Integer,Float] :orientation_x,'orientation_x' orientation_x coodinate of location
  # @option args [Integer,Float] :orientation_y,'orientation_y' orientation_y coodinate of location
  # @option args [Integer,Float] :orientation_z,'orientation_z' orientation_z coodinate of location
  # @option args [Motel::MovementStrategy] :movement_strategy,'movement_strategy' movement strategy to assign to location
  # @option args [Array<Motel::Callbacks::Movement> :movement_callbacks,'movement_callbacks' array of movement callbacks to assign to location
  # @option args [Array<Motel::Callbacks::Proximity> :proximity_callbacks,'proximity_callbacks' array of proximity callbacks to assign to location
  # @option args [Array<Motel::Callbacks::Stopped> :stopped_callbacks,'stopped_callbacks' array of stopped callbacks to assign to location
  # @option args [true,false] :restrict_view,'restrict_view' whether or not access to this location is restricted
  # @option args [true,false] :restrict_modify,'restrict_modify' whether or not modifications to this location is restricted
  # @option args [String] :remote_queue,'remote_queue' remote_queue to assign to location if any
  #
  # @example
  #   system = Motel::Location.new :id => 42
  #   planet = Motel::Location.new :id => 43, :parent => system,
  #                                :x => 100, :y => -200.5, :z => 400,
  #                                :movement_strategy => Motel::MovementStrategies::Elliptical.new(:l => 100, :e => 0.5)
   def initialize(args = {})
      # default to the stopped movement strategy
      @movement_strategy   = args[:movement_strategy]   || args['movement_strategy']   || MovementStrategies::Stopped.instance
      @movement_callbacks  = args[:movement_callbacks]  || args['movement_callbacks']  || []
      @proximity_callbacks = args[:proximity_callbacks] || args['proximity_callbacks'] || []
      @rotation_callbacks  = args[:rotation_callbacks]  || args['rotation_callbacks']  || []
      @stopped_callbacks   = args[:stopped_callbacks  ] || args['stopped_callbacks']   || []
      @children            = args[:children]            || args['children']            || []
      @parent_id           = args[:parent_id]           || args['parent_id']           || nil
      @parent              = args[:parent]              || args[:parent]

      @id                  = args[:id]                  || args['id']                  || nil

      @x, @y, @z           =
                           *(args[:coordinates]         || args['coordinates']         || [])
      @x                   = args[:x]                   || args['x']                   || @x
      @y                   = args[:y]                   || args['y']                   || @y
      @z                   = args[:z]                   || args['z']                   || @z

      @orientation_x, @orientation_y, @orientation_z =
                          *(args[:orientation]          || args['orientation']         || [])
      @orientation_x      = args[:orientation_x]        || args['orientation_x']       || @orientation_x
      @orientation_y      = args[:orientation_y]        || args['orientation_y']       || @orientation_y
      @orientation_z      = args[:orientation_z]        || args['orientation_z']       || @orientation_z

      @restrict_view       = true
      @restrict_view       = args[:restrict_view]  if args.has_key?(:restrict_view)
      @restrict_view       = args['restrict_view'] if args.has_key?('restrict_view')

      @restrict_modify     = true
      @restrict_modify     = args[:restrict_modify]  if args.has_key?(:restrict_modify)
      @restrict_modify     = args['restrict_modify'] if args.has_key?('restrict_modify')

      @remote_queue        = args[:remote_queue]        || args['remote_queue']        || nil

      # no parsing errors will be raised (invalid conversions will be set to 0), use alternate conversions / raise error ?
      @x = @x.to_f unless @x.nil?
      @y = @y.to_f unless @y.nil?
      @z = @z.to_f unless @z.nil?
      @orientation_x = @orientation_x.to_f unless @orientation_x.nil?
      @orientation_y = @orientation_y.to_f unless @orientation_y.nil?
      @orientation_z = @orientation_z.to_f unless @orientation_z.nil?

      @parent.children.push self unless @parent.nil? || @parent.children.include?(self)
   end

   # TODO add validation method

   # Update this location's attributes from other location
   #
   # @param [Motel::Location] location location from which to copy values from
   def update(location)
      @x = location.x unless location.x.nil?
      @y = location.y unless location.y.nil?
      @z = location.z unless location.z.nil?
      @orientation_x = location.orientation_x unless location.orientation_x.nil?
      @orientation_y = location.orientation_y unless location.orientation_y.nil?
      @orientation_z = location.orientation_z unless location.orientation_z.nil?
      @movement_strategy = location.movement_strategy unless location.movement_strategy.nil?
      @parent = location.parent unless location.parent.nil?
      @parent_id = location.parent_id unless location.parent_id.nil?
      @restrict_view   = location.restrict_view
      @restrict_modify = location.restrict_modify
      @remote_queue    = location.remote_queue
   end

   # Return this location's coordinates in an array
   #
   # @return [Array<Float,Float,Float>] array containing this location's x,y,z coordiantes
   def coordinates
     [@x, @y, @z]
   end

   # Return this location's orientation in an array
   def orientation
     [@orientation_x, @orientation_y, @orientation_z]
   end

   # Return this location's orientation as spherical theta/phi coordinates
   def spherical_orientation
     Motel.to_spherical(@orientation_x, @orientation_y, @orientation_z)[0..1]
   end

   # Return boolean indicating if location is oriented towards the specified coordinate
   def oriented_towards?(x, y, z)
     orientation_difference(x, y, z).all? { |od| od == 0 }
   end

   # Return angle between location's orientation and the specified coordinate.
   #
   # Angle is returned as an array containing spherical theta, phi coordinates.
   #
   # Angle differences returned may be positive or negative indicating relative
   # position of the orientation to the specified coordinate
   def orientation_difference(x, y, z)
     t,p = self.spherical_orientation
     ct,cp = Motel.to_spherical(x - @x, y - @y, z - @z)[0..1]
     [ct-t,cp-p]
   end

   # Return the root location on this location's heirarchy tree
   #
   # @return [Motel::Location]
   def root
     return self if parent.nil?
     return parent.root
   end

   # Traverse all chilren recursively, calling specified block for each
   #
   # @param [Callable] bl block to call with each child location as a param (recursively)
   def each_child(&bl)
      children.each { |child|
         if bl.arity == 1
           bl.call child
         elsif bl.arity == 2
           bl.call self, child
         end
         child.each_child &bl
      }
   end

   # Add new child to location
   #
   # @param [Motel::Location] child location to add under this one
   def add_child(child)
     child.parent.remove_child(child) if child.parent
     child.parent = self
     @children << child unless @children.include?(child) || !@children.find { |ch| ch.id == child.id }.nil?
   end

   # Remove child from location
   #
   # @param [Motel::Location,Integer] child child location to move or its string id
   def remove_child(child)
     @children.reject!{ |ch| (child.is_a?(Motel::Location) && ch == child) ||
                             (child == ch.id) }
   end

   # Return the absolute 'x' value of this location,
   # eg the sum of the x value of this location and that of all its parents
   def total_x
     return 0 if parent.nil?
     return parent.total_x + x
   end

   # Return the absolute 'y' value of this location,
   # eg the sum of the y value of this location and that of all its parents
   def total_y
     return 0 if parent.nil?
     return parent.total_y + y
   end

   # Return the absolute 'z' value of this location,
   # eg the sum of the z value of this location and that of all its parents
   def total_z
     return 0 if parent.nil?
     return parent.total_z + z
   end

   # Return the distance between this location and specified other
   #
   # @param [Motel::Location] location which to calculate distance to
   # @return [Float] distance to the specified location
   #
   # @example
   #   loc1 = Motel::Location.new :x => 100
   #   loc2 = Motel::Location.new :x => 200
   #   loc1 - loc2    # => 100
   #   loc2 - loc1    # => 100
   def -(location)
     dx = x - location.x
     dy = y - location.y
     dz = z - location.z
     Math.sqrt(dx ** 2 + dy ** 2 + dz ** 2)
   end

   # Add specified quantities to each coordinate component and return new location
   #
   # @param [Array<Integer,Integer,Integer>,Array<Float,Float,Float>] values values to add to x,y,z coordinates respectively
   # @return [Motel::Location] new location with coordinates corresponding to those locally plus the specified values
   #
   # @example
   #   loc = Motel::Location.new(:id => 42, :x => 100, :y => -100, :z => -200)
   #   loc2 = loc + [100, 100, 100]
   #   loc2   # => loc-(200, 0, -100)
   #   loc    # => loc-42(100, -100, -200)
   def +(values)
     loc = Location.new
     loc.update(self)
     loc.x += values[0]
     loc.y += values[1]
     loc.z += values[2]
     loc
   end

   # Convert location to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id,
          :x => x, :y => y, :z => z,
          :orientation_x => orientation_x,
          :orientation_y => orientation_y,
          :orientation_z => orientation_z,
          :restrict_view => restrict_view, :restrict_modify => restrict_modify,
          :parent_id => parent_id,
          :children  => children,
          :remote_queue => remote_queue,
          :movement_strategy => movement_strategy,
          :movement_callbacks => movement_callbacks,
          :proximity_callbacks => proximity_callbacks,
          :rotation_callbacks => rotation_callbacks,
          :stopped_callbacks => stopped_callbacks}
     }.to_json(*a)
   end

   # Convert location to human readable string and return it
   def to_s
     s = "location-#{id}(@#{parent_id}:"
     s += "#{x.round_to(2)},#{y.round_to(2)},#{z.round_to(2)}" unless x.nil? || y.nil? || z.nil?
     s += ")"
     s
   end

   # Create new location from json representation
   def self.json_create(o)
     loc = new(o['data'])
     return loc
   end

   # Create a random location and return it.
   # @param [Hash] args optional hash of args containing limits to the randomization
   # @option args [Float] :max,'max' max value of the x,y,z coordinates
   # @option args [Float] :min,'min' min value of the x,y,z coordinates
   # @option args [Float] :max_x,'max_x' max value of the x coordinate
   # @option args [Float] :max_y,'max_y' max value of the y coordinate
   # @option args [Float] :max_z,'max_z' max value of the z coordinate
   # @option args [Float] :min_x,'min_x' max value of the x coordinate
   # @option args [Float] :min_y,'min_y' max value of the y coordinate
   # @option args [Float] :min_z,'min_z' max value of the z coordinate
   def self.random(args = {})
     max_x = max_y = max_z = nil
     max_x = max_y = max_z = args[:max] if args.has_key?(:max)
     max_x = args[:max_x] if args.has_key?(:max_x)
     max_y = args[:max_y] if args.has_key?(:max_y)
     max_z = args[:max_z] if args.has_key?(:max_z)

     min_x = min_y = min_z = 0
     min_x = min_y = min_z = args[:min] if args.has_key?(:min)
     min_x = args[:min_x] if args.has_key?(:min_x)
     min_y = args[:min_y] if args.has_key?(:min_y)
     min_z = args[:min_z] if args.has_key?(:min_z)

     # TODO this is a little weird w/ the semantics of the 'min'
     # arguments, at some point look into changing this
     nx = rand(2) == 0 ? -1 : 1
     ny = rand(2) == 0 ? -1 : 1
     nz = rand(2) == 0 ? -1 : 1

     loc = Location.new
     loc.x = (max_x.nil? ? rand : min_x + rand(max_x - min_x)) * nx
     loc.y = (max_y.nil? ? rand : min_y + rand(max_y - min_y)) * ny
     loc.z = (max_z.nil? ? rand : min_z + rand(max_z - min_z)) * nz

     return loc
   end

end

end # module Motel
