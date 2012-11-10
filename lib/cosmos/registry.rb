# Cosmos entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# Primary server side entity tracker for Cosmos module.
#
# Provides a thread safe registry through which cosmos
# entity heirarchies and resources can be accessed.
#
# Singleton class, access via Cosmos::Registry.instance.
class Registry
  include Singleton

  # Return array of galaxies being managed
  # @return [Array<Cosmos::Galaxy>]
  def galaxies
    ret = []
    @entities_lock.synchronize {
      @galaxies.each { |g| ret << g }
    }
    return ret
  end

  # Return array of resource sources being managed
  # @return [Array<Cosmos::ResourceSource>]
  def resource_sources
    ret = []
    @entities_lock.synchronize {
      @resource_sources.each { |s| ret << s }
    }
    return ret
  end

  # Cosmos::Registry intializer
  def initialize
    init
  end

  # Reinitialize the Cosmos::Registry
  def init
    @galaxies = []
    @resource_sources = []

    @entities_lock = Mutex.new
  end

  # Run the specified block of code as a protected operation.
  #
  # This should be used when updating any cosmos entities outside
  # the scope of registry operations to protect them from concurrent access.
  #
  # @param [Array<Object>] args catch-all array of arguments to pass to block on invocation
  # @param [Callable] bl block to invoke
  def safely_run(*args, &bl)
    @entities_lock.synchronize {
      bl.call *args
    }
  end

  # Return array of classes of cosmos entity types
  def entity_types
    [Cosmos::Galaxy,
     Cosmos::SolarSystem,
     Cosmos::Star,
     Cosmos::Planet,
     Cosmos::Moon,
     Cosmos::Asteroid,
     Cosmos::JumpGate]
  end

  # Lookup and return entities in registry.
  #
  # By default, with no arguments, returns a flat list of all entities
  # tracked by the registry. Takes a hash of arguments to filter entities
  # by. If :name and/or :location is specified a single entity found
  # will be returned, else nil.
  #
  # @param [Hash] args arguments to filter cosmos entities with
  # @option args [String,:symbol] :type string or symbol representing type of entity to lookup. Valid values include
  #   * 'galaxy' / :galaxy
  #   * 'solarsystem' / :solarsystem
  #   * 'star' / :star
  #   * 'planet' / :planet
  #   * 'asteroid' / :asteroid
  #   * 'moon' / :moon
  # @option args [String] :name string name to match, if specified first matching result will be returned, nil if none found
  # @option args [Integer] :location integer location id  to match, if specified first matching result will be returned, nil if none found
  # @return [Array<CosmosEntity>,CosmosEntity,nil] one or more matching cosmos entities, empty array or nil if none found
  def find_entity(args = {})
    type = args[:type]
    name = args[:name]
    location = args[:location]
    # parent = args[:parent]

    return self if type == :universe || type == 'universe'

    entities = []
    @entities_lock.synchronize{
      @galaxies.each { |g|
        entities << g
        g.solar_systems.each { |sys|
          entities << sys
          entities << sys.star unless sys.star.nil?
          sys.planets.each { |pl|
            entities << pl
            pl.moons.each { |m|
              entities << m
            }
          }
          sys.asteroids.each { |ast|
            entities << ast
          }
        }
      }
    }

    entities.compact!

    unless type.nil?
      types = { :galaxy      => Cosmos::Galaxy,
                'galaxy'     => Cosmos::Galaxy,
                :solarsystem => Cosmos::SolarSystem,
                'solarsystem'=> Cosmos::SolarSystem,
                :star        => Cosmos::Star,
                'star'       => Cosmos::Star,
                :planet      => Cosmos::Planet,
                'planet'     => Cosmos::Planet,
                :moon        => Cosmos::Moon,
                'moon'       => Cosmos::Moon,
                :asteroid    => Cosmos::Asteroid,
                'asteroid'   => Cosmos::Asteroid,
                'Cosmos::Galaxy'      => Cosmos::Galaxy,
                'Cosmos::SolarSystem' => Cosmos::SolarSystem,
                'Cosmos::Star'        => Cosmos::Star,
                'Cosmos::Planet'      => Cosmos::Planet,
                'Cosmos::Moon'        => Cosmos::Moon,
                'Cosmos::Asteroid'    => Cosmos::Asteroid }

      entities.reject! { |e| e.class != types[type] }
    end

    unless name.nil?
      entities.reject! { |e| e.name != name }
    end

    unless location.nil?
      entities.reject! { |e| e.location.id != location }
    end

    return entities.first if args.has_key?(:name) || args.has_key?(:location)
    return entities
  end

  # Name of the registry, for entity compat reasons
  # @return ["universe"]
  def name
    "universe"
  end

  # Location of the registry, for entity compat reasons
  # @return [nil]
  def location
    nil
  end

  # Returns boolean indicating if remote cosmos retrieval can be performed for registry's children, for entity compat reasons
  # @return [false]
  def self.remotely_trackable?
    false
  end

  # Return children galaxies
  # @return [Array<Cosmos::Galaxy>]
  def children
    @galaxies
  end

  # Add galaxy to registry.
  #
  # First peforms basic checks to ensure galaxy is valid in the
  # context of the registry, after which it is added to the local galaxies array
  #
  # @param [Cosmos::Galaxy] galaxy system to add to registry
  # @raise ArgumentError if galaxy is not valid in the context of the local registry
  # @return [Cosmos::Galaxy] the galaxy just added
  def add_child(galaxy)
    raise ArgumentError, "child must be a galaxy" if !galaxy.is_a?(Cosmos::Galaxy)
    raise ArgumentError, "galaxy name #{galaxy.name} is already taken" if @galaxies.find { |g| g.name == galaxy.name }
    raise ArgumentError, "galaxy #{galaxy} already added to registry" if @galaxies.include?(galaxy)
    raise ArgumentError, "galaxy #{galaxy} must be valid" unless galaxy.valid?
    @galaxies << galaxy
    galaxy
  end

  # Remove child galaxy from registry.
  #
  # Ignores / just returns if galaxy is not found
  #
  # @param [Cosmos::Galaxy,String] child galaxy to remove from registry or its name
  def remove_child(child)
    @entities_lock.synchronize{
      @galaxies.reject! { |ch| (child.is_a?(Cosmos::Galaxy) && ch == child) ||
                               (child == ch.name) }
    }
  end

  # Returns boolean indicating if the registry has one or more child galaxies
  def has_children?
    ret = nil
    @entities_lock.synchronize{
      ret = @galaxies.size > 0
    }
    return ret
  end

  # Iterates over each child galaxy, invoking the specified
  # block with the child as a parameter and then invoking
  # 'each_child' on the child itself
  #
  # @param [Callable] bl callback block parameter
  def each_child(&bl)
    @entities_lock.synchronize{
      @galaxies.each { |g|
        bl.call self, g
        g.each_child &bl
      }
    }
  end

  # Helper method to create a new parent for the entity if it doesn't exist.
  #
  # Should be invoked before a entity is added to the registry or to another
  # entity on the heirarchy. Mostly intended to provide a mechanism to create
  # a parent to reference for remotely tracked entities (for example to create a
  # local parent for a solar system being tracked on a different server than its
  # galaxy).
  #
  # @param [CosmosEntity] entity entity to create
  # @param [String] parent_name name of entity's parent, will be looked up, not created if found
  def create_parent(entity, parent_name)
    if entity.is_a?(Cosmos::Galaxy)
      return :universe

    elsif entity.is_a?(Cosmos::SolarSystem)
      parent = find_entity :type => entity.class.parent_type, :name => parent_name
      if parent.nil?
        parent = Cosmos::Galaxy.new :name => parent_name, :remote_queue => ''
        add_child(parent)
      end

      return parent
    end

    return nil
  end

  # Return an array of {Cosmos::ResourceSource}s matching the specified criteria
  #
  # If invoked with no arguments, returns all resourse sources, else returns
  # those matching the specified criteria.
  #
  # @param [Hash] args arguments to filter cosmos entities with
  # @option args [String] :entity_id string name of the entity containing the resource to match
  # @option args [String] :resource_name string name of the resource to match
  # @option args [String] :resource_type string type of the resource to match
  # @return [Array<Cosmos::ResourceSource>] array of matching resource sources
  def resources(args = {})
    entity_id     = args[:entity_id]
    resource_name = args[:resource_name]
    resource_type = args[:resource_type]

    rs = []
    @entities_lock.synchronize{
      rs = @resource_sources.select { |rs|
             (entity_id.nil? || rs.entity.name == entity_id) &&
             (resource_name.nil? || rs.resource.name == resource_name) &&
             (resource_type.nil? || rs.resource.type == resource_type)
           }.collect { |rs| rs.resource }
    }
    rs
  end

  # Set the resource for the specified entity
  #
  # @param [String] entity_id name of the entity to add resource too, must correspond to an entity type that can accept resources
  # @param [Cosmos::Resource] resource resource to add to entity
  # @param [Integer] quantity amount of resource to add to entity
  # @return [Cosmos::ResourceSource,nil] resource source added, nil if not added
  def set_resource(entity_id, resource, quantity)
    entity = find_entity(:name => entity_id)
    return if entity.nil? || resource.nil? ||
             !entity.accepts_resource?(resource) ||
             quantity < 0

    rs = nil
    @entities_lock.synchronize{
      # if we're setting quantity to 0, just delete resource
      if quantity == 0
        @resource_sources.delete_if { |rsi| rsi.entity.name == entity_id &&
                                            rsi.resource.name == resource.name &&
                                            rsi.resource.type == resource.type }

      else
        rs = @resource_sources.find { |rsi| rsi.entity.name == entity_id &&
                                           rsi.resource.name == resource.name &&
                                           rsi.resource.type == resource.type }

        # if resource doesn't exist, create, else just set quantity
        if rs.nil?
          rs = ResourceSource.new(:entity => entity,
                                  :resource => resource,
                                  :quantity => quantity)
          @resource_sources << rs

        else
          rs.quantity = quantity
        end
      end
    }

    return rs
  end

   # Convert entities stored in registry to json representation and return
   def to_json(*a)
     @galaxies.to_json(*a)
   end

  # Save state of the registry to specified io stream
  def save_state(io)
    galaxies.each { |galaxy| io.write galaxy.to_json + "\n" }
    resource_sources.each { |rs| io.write rs.to_json + "\n" }
  end

  # restore state of the registry from the specified io stream
  def restore_state(io)
    io.each { |json|
      entity = JSON.parse(json)
      if entity.is_a?(Cosmos::Galaxy)
        add_child(entity)
      elsif entity.is_a?(Cosmos::ResourceSource)
        set_resource(entity.entity.name, entity.resource, entity.quantity)
      end
    }
  end

end

end
