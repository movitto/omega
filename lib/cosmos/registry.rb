# Cosmos entity registry
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# !!!FIXME!!! lock datastore

class Registry
  include Singleton

  # FIXME remove default accessors,
  # replace w/ custom one w/ lock to protect
  # these from concurrent access
  attr_accessor :galaxies
  attr_accessor :resource_sources

  def initialize
    init
  end

  def init
    @galaxies = []
    @resource_sources = []
  end

  def find_entity(args = {})
    type = args[:type]
    name = args[:name]
    location = args[:location]
    # parent = args[:parent]
    entities = []

    return self if type == :universe

    @galaxies.each { |g|
      if type.nil? || type == :galaxy
        if name.nil? && location.nil?
          entities << g
        elsif (!name.nil?     && (name     == g.name       )) ||
              (!location.nil? && (location == g.location.id))
          return g
        end
      else
        g.solar_systems.each { |sys|
          if type.nil? || type == :solarsystem
            if name.nil? && location.nil?
              entities << sys
            elsif (!name.nil?     && (name     == sys.name       )) ||
                  (!location.nil? && (location == sys.location.id))
              return sys
            end
          elsif type.nil? || type == :star
            if name.nil? && location.nil?
              entities << sys.star
            elsif (!name.nil?     && (name     == sys.star.name       )) ||
                  (!location.nil? && (location == sys.star.location.id))
              return sys.star
            end
          else
            sys.planets.each { |p|
              if type.nil? || type == :planet
                if name.nil? && location.nil?
                  entities << p
                elsif (!name.nil?     && (name     == p.name       )) ||
                      (!location.nil? && (location == p.location.id))
                  return p
                end
              else
                p.moons.each { |m|
                  if type.nil? || type == :moon
                    if name.nil? && location.nil?
                      entities << m
                    elsif (!name.nil?     && (name     == m.name       )) ||
                          (!location.nil? && (location == m.location.id))
                      return m
                    end
                  end
                }
              end
            }
            sys.asteroids.each { |a|
              if type.nil? || type == :asteroid
                if name.nil? && location.nil?
                  entities << a
                elsif (!name.nil?     && (name     == a.name       )) ||
                      (!location.nil? && (location == a.location.id))
                  return a
                end
              end
            }
          end
        }
      end
    }
    return (!name.nil? || !location.nil?) ? nil : entities
  end

  def children
    @galaxies
  end

  def add_child(galaxy)
    @galaxies << galaxy unless @galaxies.include?(galaxy) || !galaxy.is_a?(Cosmos::Galaxy)
  end

  def remove_child(child)
    @galaxies.reject! { |ch| (child.is_a?(Cosmos::Galaxy) && ch == child) ||
                             (child == ch.name) }
  end

  def has_children?
    return @galaxies.size > 0
  end

  def each_child(&bl)
    @galaxies.each { |g|
      bl.call self, g
      g.each_child &bl
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

    resource_sources.select { |rs|
      (entity_id.nil? || rs.entity.name == entity_id) &&
      (resource_name.nil? || rs.resource.name == resource_name) &&
      (resource_type.nil? || rs.resource.type == resource_type)
    }.collect { |rs| rs.resource }
  end

  # set the resource for the specified entity
  def set_resource(entity_id, resource, quantity)
    entity = find_entity(:name => entity_id)
    return if entity.nil? || resource.nil? || quantity < 0

    entity_resource = resources(:entity_id => entity_id,
                                :resource_name => resource.name,
                                :resoure_type  => resource.type).first
    resource_source = nil
    if entity_resource.nil?
      resource_source = ResourceSource.new(:entity => entity,
                                           :resource => resource,
                                           :quantity => quantity)
      @resource_sources << resource_source
    else
      resource_source = resource_sources.find { |rs| rs.entity.name == entity_id &&
                                                     rs.resource.name == resource.name &&
                                                     rs.resource.type == resource.type }
      resource_source.quantity = quantity
    end

    return resource_source
  end

  # Save state of the registry to specified stream
  def save_state(io)
    # TODO block new operations on registry
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
