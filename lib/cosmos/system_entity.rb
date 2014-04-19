# Base Cosmos System Entity definition
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'cosmos/entity'

module Cosmos

# Expanded Cosmos Entity which resides in a system and has some
# basic characteristics.
module SystemEntity
  include Entity

  PARENT_TYPE = 'SolarSystem'

  # {Cosmos::SolarSystem} parent of the entity
  alias :solar_system :parent
  alias :solar_system= :parent=
  alias :system_id  :parent_id
  alias :system_id= :parent_id=

  # Size of entity
  attr_accessor :size

  # Type of entity, optional entity-specific classification
  attr_accessor :type

  def init_system_entity(args={})
    attr_from_args args, :size         => nil,
                         :type         => nil,
                         :solar_system => @parent
  end

  # Return boolean indicating if system_entity is valid
  #
  # Currently tests
  # * size is valid
  # * type is valid
  def system_entity_valid?
    size_valid? && type_valid?
  end

  # Return bool indicating if size is valid
  def size_valid?
    @size.numeric?
  end

  # Return bool indicating if type is valid,
  # subclasses should override if appropriate
  def type_valid?
    true
  end

  # Return system entity json attributes
  def system_entity_json
    {:type => @type, :size => @size}
  end
end # module SystemEntity
end # module Cosmos
