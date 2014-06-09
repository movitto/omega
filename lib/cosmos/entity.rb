# Base Cosmos Entity definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/common'

module Cosmos

# Base Cosmos Entity
# Assumes PARENT_TYPE, CHILD_TYPES, and valid? are defined on module including this
module Entity
  ######################################## Config

  class << self
    # @!group Config options

    # Bool indicating if constraints should be enforced on cosmos entities
    attr_accessor :enforce_constraints

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.enforce_constraints = config.constraints
    end

    # @!endgroup
  end

  def enforce_constraints
    Entity.enforce_constraints
  end

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

  # If set to remote node, server will proxy operations relavent
  # to this entity to the specified node
  attr_accessor :proxy_to

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

  # Cosmos::Entity initializer
  #
  # @param [Hash] args hash of options to initialize entity with
  # @option args [String] :id,'id' unqiue id to assign to the entity
  # @option args [String] :name,'name' name to assign to the entity
  # @option args [Motel::Location] :location,'location' location of the entity,
  #   if not specified will automatically be created with coordinates (0,0,0)
  def init_entity(args={})
    @location = args[:location] || args[:loc]
    @location = Motel::Location.new :coordinates => [0,0,0],
                                    :orientation => [0,0,1] if @location.nil?

    @location.orientation = [0,0,1] if @location.orientation == [nil,nil,nil]
    @location.ms = args[:ms] || args[:movement_strategy] || @location.ms

    attr_from_args args, :id            => nil,
                         :name          => nil,
                         :location      => nil,
                         :proxy_to      => nil,
                         :parent_id     => nil,
                         :parent        => nil,
                         :children      =>  [],
                         :metadata      =>  {}
  end

  # Return boolean indicating if entity is valid
  #
  # Currently tests id, name, location, parent, and children are valid
  #
  # From default initialization the following needs to be set
  # to valid values to form a valid entity:
  # * id
  # * name
  # * parent_id
  # * location id
  #
  # TODO implement a centralized 'errors' mechanism so invoker can
  # quickly lookup what is wrong w/ the validation
  def entity_valid?
    id_valid? && name_valid? && parent_valid? &&
    location_valid? && children_valid?
  end

  # Return boolean indicating if entity id is valid
  def id_valid?
    !@id.nil? && @id.is_a?(String) && @id   != ""
  end

  # Return boolean indicating if entity name is valid
  def name_valid?
    !@name.nil? && @name.is_a?(String) && @name != ""
  end

  # Return boolean indicating if parent is valid
  def parent_valid?
    # TODO also verify parent_id and proxy_to aren't both set?
    (self.class::PARENT_TYPE == 'NilClass' ||
     !@proxy_to.nil? || !@parent_id.nil?) &&

    (@parent.nil? ||
     @parent.class.to_s.demodulize == self.class::PARENT_TYPE)
  end

  # Return boolean indicating if location is valid
  def location_valid?
    !@location.nil? && @location.is_a?(Motel::Location) && @location.valid?
  end

  # Return boolean indicating of all children are valid
  def children_valid?
    ch = children
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
     :parent_id => @parent_id,
     :proxy_to  => @proxy_to
    }
  end
end # module Entity
end # module Cosmos
