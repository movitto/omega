# Base Cosmos Entity definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# Base Cosmos Entity
# Assumes PARENT_TYPE, CHILD_TYPES, and valid? are defined on module including this
module Entity
  # Unique id of the entity
  attr_accessor :id

  # Human friendly name of entity
  attr_accessor :name

  # {Motel::Location} in location which entity resides under the parent
  attr_accessor :location

  # Convenience method to set movement_strategy on entity's location
  def movement_strategy=(strategy)
    @location.movement_strategy = strategy unless @location.nil?
  end

  # ID of parent to which entity belongs
  attr_accessor :parent_id

  # Parent to which entity belongs
  attr_reader :parent

  # Set parent and id
  def parent=(val)
    @parent = val

    unless val.nil?
      @parent_id = val.id
      @location.parent = val.location
    end
  end

  # Array of children which reside under parent
  attr_accessor :children

  # Additional metadata associated with entity,
  attr_accessor :metadata

  # Cosmos::Entity intializer
  #
  # @param [Hash] args hash of options to initialize entity with
  # @option args [String] :id,'id' unqiue id to assign to the entity
  # @option args [String] :name,'name' name to assign to the entity
  # @option args [Motel::Location] :location,'location' location of the entity,
  #   if not specified will automatically be created with coordinates (0,0,0)
  def init_entity(args={})
    attr_from_args args, :id            => nil,
                         :name          => nil,
                         :location      => nil,
                         :parent_id     => nil,
                         :parent        => nil,
                         :children      =>  [],
                         :metadata      =>  {}
    @location = Motel::Location.new :coordinates => [0,0,0],
                                    :orientation => [0,0,1] if @location.nil?

    @location.orientation = [0,0,1] if @location.orientation == [nil,nil,nil]

    @location.movement_strategy =
      args[:movement_strategy] if args.has_key?(:movement_strategy)
  end

  # Return boolean indicating if entity is valid
  #
  # Currently tests
  # * id is set to a valid (non-empty) string
  # * name is set to a valid (non-empty) string
  # * location is set to a valid Motel::Location
  # * parent_id is set if required
  # * parent is nil or instance of parent type
  # * children is an array of valid entities of child types
  #
  # From default initialization the following needs to be set
  # to valid values to form a valid entity:
  # * id
  # * name
  # * location
  # * parent_id
  def entity_valid?
    ch = children

    !@id.nil? && @id.is_a?(String) && @id   != "" &&
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    (self.class::PARENT_TYPE == 'NilClass' || !@parent_id.nil?) &&
    (@parent.nil? || @parent.class.to_s.demodulize == self.class::PARENT_TYPE) &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.valid? &&
     ch.is_a?(Array) &&
     ch.all?{ |c|
       self.class::CHILD_TYPES.include?(c.class.to_s.demodulize) &&
       c.valid?
     }
  end

  # Add child to entity, ensures it is not present and is valid before adding
  def add_child(child)
    raise ArgumentError, child unless self.class::CHILD_TYPES.
                                      include?(child.class.to_s.demodulize) &&
                                      child.valid? && !has_child?(child)

    # ensure child of valid type
    child.location.parent_id = location.id
    child.parent = self
    children << child
    child
  end
  alias :<< :add_child

  # Remove child from entity
  def remove_child(child)
    children.reject! { |c| c.id == (child.is_a?(String) ? child : child.id) }
  end

  # Return bool indicating if entity has children
  def has_children?
    children.size > 0
  end

  # Return bool indicating if entity has child
  def has_child?(child)
    !children.find { |c| c.id == (child.is_a?(String) ? child : child.id) }.nil?
  end

  # Iterate over children calling block w/ self and each child before calling
  # each_child on children
  def each_child(&bl)
    children.each { |sys|
      bl.call self, sys
      sys.each_child &bl
    }
  end

  # By default cosmos entities do not accept resources
  #   (overridden in certain subclasses)
  def accepts_resource?(res)
    false
  end

  # Convert entity to string
  def to_s
    self.class.to_s.demodulize + '-' + self.name.to_s
  end

  # Return entity json attributes
  def entity_json
    {:id        => @id,
     :name      => @name,
     :location  => @location,
     :children  => @children,
     :metadata  => @metadata,
     :parent_id => @parent_id
    }
  end

end # module Entity

# Expanded Cosmos Entity which provides an environment
#
# Assumes class including this defines 'NUM_BACKGROUNDS'
module EnvEntity
  # Environment ackground
  attr_accessor :background

  def init_env_entity(args = {})
    attr_from_args args, :background => (rand(self.class::NUM_BACKGROUNDS) + 1)
  end

  # Return env entity json attributes
  def env_entity_json
    {:background => @background}
  end
end

# Expanded Cosmos Entity which resides in a system and has some
# basic characteristics.
#
# Assumes class including this defines VALIDATE_SIZE and VALIDATE_COLOR callbacks
# and RAND_SIZE and RAND_COLOR generators
module SystemEntity
  include Entity

  PARENT_TYPE = 'SolarSystem'

  # {Cosmos::SolarSystem} parent of the entity
  alias :solar_system :parent
  alias :solar_system= :parent=
  alias :system_id  :parent_id
  alias :system_id= :parent_id=

  # Color of entity
  attr_accessor :color

  # Size of entity
  attr_accessor :size

  def init_system_entity(args={})
    attr_from_args args, :size  => self.class::RAND_SIZE.call,
                         :color => self.class::RAND_COLOR.call,
                         :solar_system => @parent
  end

  # Return boolean indicating if system_entity is valid
  #
  # Currently tests
  # * color is set to valid string
  # * size is set to valid value
  def system_entity_valid?
    @size.numeric? && self.class::VALIDATE_SIZE.call(@size) &&
    @color.is_a?(String) && self.class::VALIDATE_COLOR.call(@color)
  end

  # Return system entity json attributes
  def system_entity_json
    {:color => @color, :size => @size}
  end
end

end # module Cosmos
