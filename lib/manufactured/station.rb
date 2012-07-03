# Manufactured Station definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Station
  attr_accessor :id
  attr_accessor :user_id
  attr_accessor :type
  attr_accessor :location
  attr_accessor :size

  attr_accessor :solar_system

  # map of resources contained in the station to quantities
  attr_reader :resources

  # cargo properties
  attr_accessor :cargo_capacity
  # see cargo_quantity below

  STATION_TYPES = [:defense, :offense, :mining, :exploration, :science,
                   :technology, :manufacturing, :commerce]

  STATION_SIZES = {:defense => 35, :offense => 35, :mining => 27,
                   :exploration => 20, :science => 20,
                   :technology => 20, :manufacturing => 40,
                   :commerce => 30}

  # TODO right now just return a fixed cost for every station, eventually make more variable
  def self.construction_cost(type)
    100
  end


  def initialize(args = {})
    @id       = args['id']       || args[:id]
    @type     = args['type']     || args[:type]
    @type     = @type.intern if !@type.nil? && @type.is_a?(String)
    @type     = STATION_TYPES[rand(STATION_TYPES.size)] if @type.nil?
    @location = args['location'] || args[:location]
    @user_id  = args['user_id']  || args[:user_id]
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : STATION_SIZES[@type])

    @solar_system = args['solar_system'] || args[:solar_system]

    @resources = args[:resources] || args['resources'] || {}

    # FIXME make variable
    @cargo_capacity = 10000

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def valid?
    !@id.nil? && @id.is_a?(String) && @id != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) &&
    !@user_id.nil? && @user_id.is_a?(String) && # ensure user id corresponds to actual user ?
    !@type.nil? && STATION_TYPES.include?(@type) &&
    !@size.nil? && @size == STATION_SIZES[@type] &&
    !@solar_system.nil? && @solar_system.is_a?(Cosmos::SolarSystem) &&
    @resources.is_a?(Hash) && @resources.select { |id,q| !id.is_a?(String) || !(q.is_a?(Integer) || q.is_a?(Float)) }.empty? # TODO verify resources are valid in context of ship
    # TODO validate cargo properties when they become variable
  end

  def parent
    return @solar_system
  end

  def parent=(system)
    @solar_system = system
  end

  def add_resource(resource_id, quantity)
    @resources[resource_id] ||= 0
    @resources[resource_id] += quantity
  end

  def remove_resource(resource_id, quantity)
    return unless @resources.has_key?(resource_id) ||# TODO throw exception?
                  @resources[resource_id] >= quantity
    @resources[resource_id] -= quantity
  end

  def cargo_quantity
    q = 0
    @resources.each { |id, quantity|
      q += quantity
    }
    q
  end

  # use this station to construct new manufactured entities
  def construct(args = {})
    # TODO verify station is of manufacturing type ?
    # TODO construction time/delay
    # TODO constrain args to permitted values
    entity_type = args[:entity_type]
    entity      = nil
    cargs       = {}
    cclass      = nil

    if entity_type == "Manufactured::Ship"
      cargs = {:id => Motel.gen_uuid,
               :type => :frigate}.merge(args)
      cclass = Manufactured::Ship
    elsif entity_type == "Manufactured::Station"
      cargs = {:id => Motel.gen_uuid,
               :type => :manufacturing}.merge(args)
      cclass = Manufactured::Station
    end

    return nil if cclass.nil?

    # verify enough resources are locally present to construct entity
    cost = cclass.construction_cost(cargs[:type])
    if cargo_quantity < cost
      return nil
    end

    # remove resources from the station
    # TODO when entities are mapped to specific resources and quantities
    # needed to construct them, we can be more discreminate here
    remaining = cost
    @resources.each { |id,quantity|
      if quantity >= remaining
        @resources[id] -= remaining
        break
      else
        remaining -= quantity
        @resources[id] = 0
      end
    }

    # instantiate the new entity
    entity = cclass.new cargs unless cclass.nil?

    unless entity.nil?
      entity.parent = self.parent

      # create entity at nearby location
      entity.location = Motel::Location.new # TODO allow user to specify alternate location (& move entity to it if permissable)
      entity.location.x = self.location.x + 10
      entity.location.y = self.location.y + 10
      entity.location.z = self.location.z + 10
      entity.location.parent = self.location.parent
    end

    entity
  end

  def to_s
    "station-#{@id}"
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:id => id, :user_id => user_id, :type => type, :size => size, :location => @location, :solar_system => @solar_system,
          :resources => @resources}
     }.to_json(*a)
   end

   def self.json_create(o)
     ship = new(o['data'])
     return ship
   end

end
end
