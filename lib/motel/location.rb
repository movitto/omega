# The Location entity
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'time'
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
class Location

   # ID of location
   attr_accessor :id

   # ID of location's parent
   attr_accessor :parent_id

   # Set location's parent_id
   #
   # (nullifies parent if changing)
   # @param [Integer] parent_id new parent id to set
   def parent_id=(parent_id)
     @parent = nil if parent_id != @parent_id
     @parent_id = parent_id
   end

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
     @parent_id = @parent.nil? ? nil : @parent.id
   end

   # Unit vector corresponding to Orientation of the location
   attr_accessor :orientation_x, :orientation_y, :orientation_z
   alias :orx :orientation_x
   alias :orx= :orientation_x=
   alias :ory :orientation_y
   alias :ory= :orientation_y=
   alias :orz :orientation_z
   alias :orz= :orientation_z=

   # [Motel::MovementStrategy] Movement strategy through which to move location
   attr_accessor :movement_strategy
   alias :ms :movement_strategy
   alias :ms= :movement_strategy=

   # true/false indicating if movement strategy is stopped
   def stopped?
     self.movement_strategy == Motel::MovementStrategies::Stopped.instance
   end

  # Next movement strategy, optionally used to register a movement strategy
  # which to set next (this is not performed by motel / up to the end user)
  attr_accessor :next_movement_strategy


   # [Hash<String, Motel::Callback>] Callbacks to be invoked on various events
   attr_accessor :callbacks

   # Boolean flag indicating if permission checks
   # should restrict access to this location
   attr_accessor :restrict_view

   # Boolean flag indicating if permission checks
   # should restrict modification of this location
   attr_accessor :restrict_modify

   # Time the location was last moved.
   # Used internally in the motel subsystem
   attr_accessor :last_moved_at

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
  # @option args [Hash<String,Motel::Callbacks> :callbacks,'callbacks' hash of events/callbacks to assign to location
  # @option args [true,false] :restrict_view,'restrict_view' whether or not access to this location is restricted
  # @option args [true,false] :restrict_modify,'restrict_modify' whether or not modifications to this location is restricted
   def initialize(args = {})
      @x, @y, @z = *(args[:coordinates] || args['coordinates'] || [])

      @orientation_x, @orientation_y, @orientation_z =
        *(args[:orientation] || args['orientation'] || [])

      # default to the stopped movement strategy
      attr_from_args args,
        :movement_strategy => MovementStrategies::Stopped.instance,
        :next_movement_strategy => nil,
        :callbacks         => Hash.new { |h,k| h[k] = [] },
        :children          => [],
        :parent            => nil,
        :parent_id         => nil,
        :id                => nil,
        :x                 => @x,
        :y                 => @y,
        :z                 => @z,
        :orientation_x     => @orientation_x,
        :orientation_y     => @orientation_y,
        :orientation_z     => @orientation_z,
        :orx               => @orientation_x,
        :ory               => @orientation_y,
        :orz               => @orientation_z,
        :restrict_view     => true,
        :restrict_modify   => true,
        :last_moved_at     => nil

      self.last_moved_at = Time.parse(self.last_moved_at) if self.last_moved_at.is_a?(String)

      # convert string callback keys into symbols
      callbacks.keys.each { |k|
        # FIXME ensure string correspond's to
        # valid callback type before interning
        if k.is_a?(String)
          callbacks[k.intern] = callbacks[k]
          callbacks.delete(k)
        end
      }

      # no parsing errors will be raised (invalid conversions will be set to 0),
      # TODO use alternate conversions / raise error ?
      [:@x, :@y, :@z,
       :@orientation_x, :@orientation_y, :@orientation_z].each { |p|
        v = self.instance_variable_get(p)
        self.instance_variable_set(p, v.to_f) unless v.nil?
      }
   end

   # Update this location's attributes from other location
   #
   # @param [Motel::Location] location location from which to copy values from
   def update(location)
      update_from(location, :x, :y, :z, :parent, :parent_id,
                            :orientation_x, :orientation_y, :orientation_z,
                            :movement_strategy, :next_movement_strategy,
                            :restrict_view, :restrict_modify, :last_moved_at)
   end

   # Validate the location's properties
   # 
   # @return bool indicating if the location is valid or not
   #
   # Currently tests
   # * id is set
   # * x, y, z are numeric
   # * orientation is numeric
   # * movement strategy is valid
   def valid?
     !@id.nil? &&

     [@x, @y, @z, @orientation_x,@orientation_y, @orientation_z].
       all? { |i| i.numeric? } &&

     @movement_strategy.kind_of?(MovementStrategy) &&
     @movement_strategy.valid?
   end

   # Invoke callbacks for the specified event
   def raise_event(evnt, *args)
     @callbacks[evnt].each { |cb|
       cb.invoke self, *args if cb.should_invoke? self, *args
     } if @callbacks.has_key?(evnt)
   end

   # Return this location's coordinates in an array
   #
   # @return [Array<Float,Float,Float>] array containing this 
   # location's x,y,z coordinates
   def coordinates
     [@x, @y, @z]
   end

   # Set this location's coordiatnes
   def coordinates=(*c)
     c.flatten! if c.first.is_a?(Array)
     @x, @y, @z = *c
   end

   # Return this location's orientation in an array
   def orientation
     [@orientation_x, @orientation_y, @orientation_z]
   end

   # Set this location's orientation
   def orientation=(*o)
     o.flatten! if o.first.is_a?(Array)
     @orientation_x, @orientation_y, @orientation_z = *o
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
     @children << child unless @children.include?(child)
   end

   # Remove child from location
   #
   # @param [Motel::Location,Integer] child child location to move or its string id
   def remove_child(child)
     @children.reject!{ |ch| ch == child || ch.id == child }
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
          :movement_strategy => movement_strategy,
          :next_movement_strategy => next_movement_strategy,
          :callbacks => callbacks,
          :last_moved_at =>
            last_moved_at.nil? ? nil : last_moved_at.strftime("%d %b %Y %H:%M:%S.%5N")}
     }.to_json(*a)
   end

   # Convert location to human readable string and return it
   def to_s
     s = "loc##{id}" +
         "(@#{parent_id.nil? ? nil : parent_id[0...8]}"
     if coordinates.size == 3 && coordinates.all?{ |c| c.numeric? }
       s += ":#{x.round_to(2)},#{y.round_to(2)},#{z.round_to(2)}"
     end
     if orientation.size == 3 && orientation.all? { |o| o.numeric? }
       s += ">#{orx.round_to(2)},#{ory.round_to(2)},#{orz.round_to(2)}"
     end
     s += " via #{movement_strategy}"
     s += ")"
     s
   end

   # Create new location from json representation
   def self.json_create(o)
     loc = new(o['data'])
     return loc
   end

   # Create a minimal valid location with id
   def self.basic(id)
     Location.new :coordinates => [0,0,0], :orientation => [0,0,1], :id => id
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

     loc = Location.new :orientation => [0,0,1]
     loc.x = ((min_x.nil? ? 0 : min_x) + (max_x.nil? ? rand : rand(max_x - min_x))) * nx
     loc.y = ((min_y.nil? ? 0 : min_y) + (max_y.nil? ? rand : rand(max_y - min_y))) * ny
     loc.z = ((min_z.nil? ? 0 : min_z) + (max_z.nil? ? rand : rand(max_z - min_z))) * nz

     return loc
   end

end

end # module Motel
