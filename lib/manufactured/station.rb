# Manufactured Station definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Manufactured
class Station
  attr_accessor :id
  attr_accessor :user_id
  attr_accessor :size

  # hash of operation names to array of errors invoked during operation
  attr_accessor :errors
  def clear_errors(args = {})
    if args.has_key?(:of_type)
      @errors[args[:of_type]] = []
    else
      @errors = {}
    end
  end

  attr_reader :location
  def location=(val)
    @location = val
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  attr_reader :type
  def type=(val)
    @type = val
    @size = STATION_SIZES[val]
  end

  # system station is in
  attr_reader :solar_system
  def solar_system=(val)
    @solar_system = val
    @location.parent = parent.location unless parent.nil? || @location.nil?
  end

  # movement properties
  attr_accessor :movement_speed

  # map of resources contained in the station to quantities
  attr_reader :resources

  # docking properties
  attr_reader :docking_distance

  # cargo properties
  attr_accessor :cargo_capacity
  # see cargo_quantity below

  # max distance which construction occurs
  attr_reader :construction_distance

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
    @user_id  = args['user_id']  || args[:user_id]
    @size     = args['size']     || args[:size] || (@type.nil? ? nil : STATION_SIZES[@type])

    @errors   = args[:errors]    || args['errors'] || {}

    @resources = args[:resources] || args['resources'] || {}

    # TODO make variable
    @movement_speed = 5
    @cargo_capacity = 10000
    @docking_distance = 100
    @transfer_distance = 100
    @construction_distance = 50

    self.solar_system = args['solar_system'] || args[:solar_system]
    self.location = args['location'] || args[:location]

    self.location = Motel::Location.new if @location.nil?
    @location.x = 0 if @location.x.nil?
    @location.y = 0 if @location.y.nil?
    @location.z = 0 if @location.z.nil?
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

  def dockable?(ship)
    # TODO at some point we may want to limit
    # the number of ships able to be ported at a station at a given time,
    # restrict this via station type, add a toggleable flag, etc
    (ship.location.parent.id == @location.parent.id) &&
    (ship.location - @location) <= @docking_distance &&
    !ship.docked?
  end

  def parent
    return self.solar_system
  end

  def parent=(system)
    self.solar_system = system
  end

  def add_resource(resource_id, quantity)
    raise Omega::OperationError, "station cannot accept resource" unless can_accept?(resource_id, quantity) # should we define an exception heirarchy local to manufactured so as not to pull in omega here?
    @resources[resource_id] ||= 0
    @resources[resource_id] += quantity
  end

  def remove_resource(resource_id, quantity)
    unless @resources.has_key?(resource_id) && @resources[resource_id] >= quantity
      raise Omega::OperationError, "ship does not contain specified quantity of resource" 
    end
    @resources[resource_id] -= quantity
    @resources.delete(resource_id) if @resources[resource_id] <= 0
  end

  def cargo_quantity
    q = 0
    @resources.each { |id, quantity|
      q += quantity
    }
    q
  end

  def can_transfer?(to_entity, resource_id, quantity)
    @id != to_entity.id &&
    @resources.has_key?(resource_id) &&
    @resources[resource_id] >= quantity &&
    (@location.parent.id == to_entity.location.parent.id) &&
    ((@location - to_entity.location) <= @transfer_distance)
  end

  def can_accept?(resource_id, quantity)
    self.cargo_quantity + quantity <= @cargo_capacity
  end

  # determine if the station can construct a new entity w/ the specified args
  def can_construct?(args = {})
    entity_type = args[:entity_type]
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

    # TODO also check if entity can be constructed in system ?
    @errors[:construction] ||= []
    if @type != :manufacturing
      @errors[:construction] << "not manufacturing station"
    elsif cclass.nil?
      @errors[:construction] << "cannot construct entity of type #{entity_type}"
    elsif cargo_quantity < cclass.construction_cost(cargs[:type])
      @errors[:construction] << "insufficient resources"
    else
      return true
    end
    return false
  end

  # use this station to construct new manufactured entities
  def construct(args = {})
    # verify station is of manufacturing type
    return nil unless @type == :manufacturing

    # FIXME construction time/delay
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

      entity.location.parent = self.location.parent
      entity.location.parent_id = self.location.parent.id

      # allow user to specify coordinates unless too far away
      # in which case, construct at closest location to specified location withing construction distance
      distance = entity.location - self.location
      if distance > @construction_distance
        dx = (entity.location.x - self.location.x) / distance
        dy = (entity.location.y - self.location.y) / distance
        dz = (entity.location.z - self.location.z) / distance
        entity.location.x = dx * @construction_distance
        entity.location.y = dy * @construction_distance
        entity.location.z = dz * @construction_distance
      end
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
         {:id => id, :user_id => user_id,
          :type => type, :size => size,
          :errors => errors,
          :docking_distance => @docking_distance,
          :location => @location,
          :solar_system => @solar_system,
          :resources => @resources}
     }.to_json(*a)
   end

   def self.json_create(o)
     ship = new(o['data'])
     return ship
   end

end
end
