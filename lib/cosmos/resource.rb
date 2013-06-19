# Cosmos Resource definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos

# http://en.wikipedia.org/wiki/Material
#
# Consumable entity, usually associated with a Cosmos entity for extraction
# or a Manufacturing entity for use.
class Resource
  # ID of the resource
  attr_accessor :id

  # Type of resource
  def type ; id.split('-').first end

  # Name of resource
  def name ; id.split('-').last end

  # Id of entity which resource is assigned
  attr_accessor :entity_id

  # Entity which resource is assigned
  attr_reader :entity

  # Set the entity and entity_id
  def entity=(val)
    @entity = val
    @entity_id = val.id unless val.nil?
  end

  # Quantity of resource assigned to entity
  attr_accessor :quantity

  # Resource initializer
  #
  # @param [Hash] args hash of options to initialize star with
  # @option args [Cosmos::Resource] :resource,'resource' resource which to copy attributes from
  # @option args [String] :id,'id' id to assign to the resource
  # @option args [String] :entity,'entity' entity to assign to the resource
  # @option args [Integer] :quantity,'quantity' amount of resource present in resource_source
  def initialize(args = {})
    attr_from_args args, :id     => nil,
                         :entity_id => nil,
                         :entity => nil,
                         :quantity => 0

    #resource = args['resource'] || args[:resource]
    #unless resource.nil? ...
  end

  # Return boolean indicating if this resource is valid.
  #
  # Ensures:
  # * is is of valid format
  # * entity_id is not nil
  # * entity is nil or valid
  def valid?
    @id.is_a?(String) && @id =~ /[a-zA-Z0-9]*-[a-zA-Z0-9]*/ &&
    !@entity_id.nil? &&
    (@entity.nil? || @entity.valid?) &&
     @quantity.numeric?
  end

  # Convert resource to string
  def to_s
    "resource-#{@id}" +
    ((!@entity.nil? && @quantity > 0) ?
      " (#{@quantity} at #{@entity.id})" :
      "")
  end

  # Convert resource to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id       => id,
                       :quantity => quantity,
                       :entity_id => entity_id }
    }.to_json(*a)
  end

  # Create new resource from json representation
  def self.json_create(o)
    rs = new(o['data'])
    return rs
  end
end # class Resource
end # module Cosmos
