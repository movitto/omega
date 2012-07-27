# Cosmos entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

class Registry
  include Singleton

  # galaxies we are managing
  def galaxies
    ret = []
    @entities_lock.synchronize {
      @galaxies.each { |g| ret << g }
    }
    return ret
  end

  # resource sources we are managing
  def resource_sources
    ret = []
    @entities_lock.synchronize {
      @resource_sources.each { |s| ret << s }
    }
    return ret
  end

  def initialize
    init
  end

  def init
    @galaxies = []
    @resource_sources = []

    @entities_lock = Mutex.new
  end

  # runs a block of code as an operation protected by the entities lock
  def safely_run(*args, &bl)
    @entities_lock.synchronize {
      bl.call *args
    }
  end

  def entity_types
    [Cosmos::Galaxy,
     Cosmos::SolarSystem,
     Cosmos::Star,
     Cosmos::Planet,
     Cosmos::Moon,
     Cosmos::Asteroid,
     Cosmos::JumpGate]
  end

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
                'asteroid'   => Cosmos::Asteroid }
      entities.reject! { |e| e.class != types[type] }
    end

    unless name.nil?
      entities.reject! { |e| e.name != name }
    end

    unless location.nil?
      entities.reject! { |e| e.location.id != location }
    end

    return entities.first unless name.nil? && location.nil?
    return entities
  end

  def name
    "universe"
  end

  def location
    nil
  end

  def self.remotely_trackable?
    false
  end

  def children
    @galaxies
  end

  def add_child(galaxy)
    raise ArgumentError, "child must be a galaxy" if !galaxy.is_a?(Cosmos::Galaxy)
    raise ArgumentError, "galaxy name #{galaxy.name} is already taken" if @galaxies.find { |g| g.name == galaxy.name }
    raise ArgumentError, "galaxy #{galaxy} already added to registry" if @galaxies.include?(galaxy)
    raise ArgumentError, "galaxy #{galaxy} must be valid" unless galaxy.valid?
    @galaxies << galaxy
    galaxy
  end

  def remove_child(child)
    @entities_lock.synchronize{
      @galaxies.reject! { |ch| (child.is_a?(Cosmos::Galaxy) && ch == child) ||
                               (child == ch.name) }
    }
  end

  def has_children?
    ret = nil
    @entities_lock.synchronize{
      ret = @galaxies.size > 0
    }
    return ret
  end

  def each_child(&bl)
    @entities_lock.synchronize{
      @galaxies.each { |g|
        bl.call self, g
        g.each_child &bl
      }
    }
  end

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

  # return the resource sources for the specified entity
  def resources(args = {})
    entity_id     = args[:entity_id]
    resource_name = args[:resource_name]
    resource_type = args[:resource_type]

    rs = []
    @entities_lock.synchronize{
      rs = resource_sources.select { |rs|
             (entity_id.nil? || rs.entity.name == entity_id) &&
             (resource_name.nil? || rs.resource.name == resource_name) &&
             (resource_type.nil? || rs.resource.type == resource_type)
           }.collect { |rs| rs.resource }
    }
    rs
  end

  # set the resource for the specified entity
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

   def to_json(*a)
     @galaxies.to_json(*a)
   end

  # Save state of the registry to specified stream
  def save_state(io)
    galaxies.each { |galaxy| io.write galaxy.to_json + "\n" }
    resource_sources.each { |rs| io.write rs.to_json + "\n" }
  end

  # restore state of the registry from the specified stream
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
