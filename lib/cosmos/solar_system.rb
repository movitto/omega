# Cosmos SolarSystem definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Planetary_system
#
# Cosmos entity residing in a galaxy containing a star,
# planets, asteroid, and jump gates.
class SolarSystem
  # Unique name of the solar system
  attr_accessor :name
  alias :id :name

  # {Motel::Location} at which solar system resides in its parent galaxy
  attr_accessor :location

  # {Cosmos::Galaxy} parent of the solar system
  attr_reader :galaxy

  # Child {Cosmos::Star} tracked locally
  attr_reader :star

  # Array of child {Cosmos::Planet} tracked locally
  attr_reader :planets

  # Array of child {Cosmos::JumpGate} tracked locally
  attr_reader :jump_gates

  # Array of child {Cosmos::Asteroid} tracked locally
  attr_reader :asteroids

  MAX_BACKGROUNDS = 6

  # Background to render solar system w/ (TODO this shouldn't be here / should be up to client)
  attr_accessor :background

  # Remote queue which to retrieve child entities from if any (may be nil)
  attr_accessor :remote_queue

  def id
    return @name
  end

  # Cosmos::SolarSystem intializer
  # @param [Hash] args hash of options to initialize solar system with
  # @option args [String] :name,'name' unqiue name to assign to the solar system
  # @option args [Motel::Location] :location,'location' location of the solar system,
  #   if not specified will automatically be created with coordinates (0,0,0)
  # @option args [Cosmos::Star>] :star,'star' star to assign to solar system
  # @option args [Array<Cosmos::Planet>] 'planets' array of planets to assign to solar system
  # @option args [Array<Cosmos::JumpGate>] 'jump_gates' array of jump gates to assign to solar system
  # @option args [Array<Cosmos::Asteroid>] 'asteroids' array of asteroids to assign to solar system
  # @option args [String] :remote_queue,'remote_queue' remote_queue to assign to solar system if any
  # @option args [String] :background,'background' background to assign to the solar system (else randomly generated)
  def initialize(args = {})
    @name       = args['name']       || args[:name]
    @location   = args['location']   || args[:location]
    @star       = args['star']       || nil
    @galaxy     = args['galaxy']     || args[:galaxy]
    @planets    = args['planets']    || []
    @jump_gates = args['jump_gates'] || []
    @asteroids  = args['asteroids']  || []
    @remote_queue = args['remote_queue'] || args[:remote_queue] || nil

    @background = args['background'] || args[:background] || "system#{rand(MAX_BACKGROUNDS-1)+1}"

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  # Return boolean indicating if this solar system is valid.
  #
  # Tests the various attributes of the SolarSystem, returning 'true'
  # if everything is consistent, else false.
  #
  # Currently tests
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location and is not moving
  # * parent galaxy is set to a Cosmos::Galaxy
  # * planets is an array of valid Cosmos::Planet instances
  # * asteroids is an array of valid Cosmos::Asteroid instances
  # * jump_gates is an array of valid Cosmos::JumpGate instances
  # * star is nil or a valid Cosmos::Star instances
  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@galaxy.nil? || @galaxy.is_a?(Cosmos::Galaxy)) &&
    @planets.is_a?(Array) && @planets.find { |p| !p.is_a?(Cosmos::Planet) || !p.valid? }.nil? &&
    @asteroids.is_a?(Array) && @asteroids.find { |a| !a.is_a?(Cosmos::Asteroid) || !a.valid? }.nil? &&
    @jump_gates.is_a?(Array) && @jump_gates.find { |j| !j.is_a?(Cosmos::JumpGate) || !j.valid? }.nil? &&
    (@star.nil? || (@star.is_a?(Cosmos::Star) && @star.valid?))
  end

  # Return boolean indicating if this solar system can accept the specified resource
  # @return false
  def accepts_resource?(res)
    false
  end

  # Returns the {Cosmos::Registry} lookup key corresponding to the entity's parent
  # @return [:galaxy]
  def self.parent_type
    :galaxy
  end

  # Returns boolean indicating if remote cosmos retrieval can be performed for entity's children
  # @return [true]
  def self.remotely_trackable?
    true
  end

  # Return galaxy parent of the SolarSystem
  # @return [Cosmos::Galaxy]
  def parent
    @galaxy
  end

  # Set galaxy parent of the SolarSystem
  # @param [Cosmos::Galaxy] galaxy
  def parent=(galaxy)
    @galaxy = galaxy
  end

  # Return array containing child planets, jump gates, asteroids, and star
  # @return [Array<Cosmos::Planet,Cosmos::JumpGate,Cosmos::Asteroid,Cosmos::Star]
  def children
    @planets + @jump_gates + @asteroids + (@star.nil? ? [] : [@star])
  end

  # Add child planet, jump gate, asteroid, or star to solar system
  #
  # Performs basic checks to ensure child is valid in the context
  # of the solar system, after it is added to the local array tracking
  # the specified entity type
  #
  # @param [Cosmos::Planet,Cosmos::JumpGate,Cosmos::Asteroid,Cosmos::Star] child child entity to add to solar system
  # @raise ArgumentError if the child entity is invalid in the context of the solar system
  # @return [Cosmos::Planet,Cosmos::JumpGate,Cosmos::Asteroid,Cosmos::Star] the child just added
  def add_child(child)
    raise ArgumentError,
          "child must be a planet, jump gate, asteroid, star" if ![Cosmos::Planet,
                                                                   Cosmos::JumpGate,
                                                                   Cosmos::Asteroid,
                                                                   Cosmos::Star].include?(child.class)
    child.parent = self
    child.location.parent_id = location.id
    child.location.parent = location

    if child.is_a? Planet
      raise ArgumentError, "planet name #{child.name} is already taken" if @planets.find { |p| p.name == child.name }
      raise ArgumentError, "planet #{child} already added to system" if @planets.include?(child)
      raise ArgumentError, "planet #{child} must be valid" unless child.valid?
      @planets << child

    elsif child.is_a? JumpGate
      #raise ArgumentError, "jump gate to #{child.endpoint.name} is already added" if @jump_gates.find { |j| j.endpoint.name == child.endpoing.name }
      raise ArgumentError, "jump gate #{child} already added to system" if @jump_gates.include?(child)
      raise ArgumentError, "jump gate #{child} must be valid" unless child.valid?
      @jump_gates << child

    elsif child.is_a? Asteroid
      raise ArgumentError, "asteroid name #{child.name} is already taken" if @asteroids.find { |a| a.name == child.name }
      raise ArgumentError, "asteroid #{child} already added to system" if @asteroids.include?(child)
      raise ArgumentError, "asteroid #{child} must be valid" unless child.valid?
      @asteroids << child

    elsif child.is_a? Star
      #raise ArgumentError, "star name #{child.name} already associated with system" if @star.name == child.name
      #raise ArgumentError, "star #{child} already assoicated with system" if @star == child
      raise ArgumentError, "star #{child} must be valid" unless child.valid?

      @star = child
    end

    child
  end

  # Remove child entity from planet
  #
  # Ignores / just return if child is not found
  #
  # @param [Cosmos::Planet,Cosmos::JumpGate,Cosmos::Asteroid,Cosmos::Star] child entity to remove from solar system or its name
  def remove_child(child)
    @planets.reject! { |ch| (child.is_a?(Cosmos::Planet) && ch == child) ||
                            (child == ch.name) }
    @jump_gates.reject! { |ch| (child.is_a?(Cosmos::JumpGate) && ch == child) } # TODO compare string against jg.endpoint.name ?
    @asteroids.reject!  { |ch| (child.is_a?(Cosmos::Asteroid) && ch == child) ||
                               (child == ch.name) }
    @star = nil if (child.is_a?(Cosmos::Star) && @star == child) || (!@star.nil? && child == @star.name)
  end

  # Iterates over all children (star, planets, jump gates, and asteroids),
  # invoking the specified block w/ the child as a parameter and then
  # invoking 'each_child' on the child itself
  #
  # @param [Callable] bl callback block parameter
  def each_child(&bl)
    bl.call self, star unless star.nil?
    @planets.each { |planet|
      bl.call self, planet
      planet.each_child &bl
    }
    @jump_gates.each { |gate|
      bl.call self, gate
    }
    @asteroids.each { |asteroid|
      bl.call self, asteroid
    }
  end

  # Returns boolean indicating if the system has children
  def has_children?
    !@star.nil? || @planets.size > 0 || @jump_gates.size > 0 || @asteroids.size > 0
  end

  # Returns boolean indicating if solar system has the specified child
  #
  # @param [String] child name of child star,planet,asteroid which to look for
  # @return [true,false] indicating if system has child
  def has_child?(child)
    return (!@star.nil? && @star.name == child) ||
           !@planets.find { |pl| pl.name == child }.nil? ||
           !@asteroids.find { |ast| ast.name == child } .nil?
  end

  # Convert solar system to human readable string and return it
  def to_s
    "solar_system-#{@name}"
  end

   # Convert solar system to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location, :galaxy_name => (@galaxy ? @galaxy.name : nil),
          :star => @star, :planets => @planets, :jump_gates => @jump_gates,
          :asteroids => @asteroids, :background => @background, :remote_queue => remote_queue}
     }.to_json(*a)
   end

   # Create new solar system from json representation
   def self.json_create(o)
     solar_system = new(o['data'])
     return solar_system
   end

end
end
