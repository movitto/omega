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

  # String ame of the resource
  attr_accessor :name

  # String classification of the resource
  attr_accessor :type

  # Resource initializer
  #
  # @param [Hash] args hash of options to initialize star with
  # @option args [Cosmos::Resource] :resource,'resource' resource which to copy name and type from
  # @option args [String] :name,'name' name to assign to the resource
  # @option args [String] :type,'type' type to assign to the resource
  def initialize(args = {})
    resource = args['resource'] || args[:resource]

    unless resource.nil?
      @name = resource.name
      @type = resource.type
    end

    @name = args['name']  || args[:name] || @name
    @type = args['type']  || args[:type] || @type
  end

  # Return boolean indicating if this resource is valid.
  #
  # Tests the various attributes of the Resource, returning 'true'
  # if everything is consistent, else false.
  #
  # * name is set to a string
  # * type is set to a string
  def valid?
    @name.is_a?(String) && @type.is_a?(String)
  end

  # Returns unique identifier of the resource consisting of it's type and name
  def id
    "#{@type}-#{@name}"
  end

  # Convert resource to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :name => name, :type => type}
    }.to_json(*a)
  end

  # Create new resource from json representation
  def self.json_create(o)
    rs = new(o['data'])
    return rs
  end
end

# http://en.wikipedia.org/wiki/Natural_resource
#
# Association between a resource and a cosmos entity that contains
# a specified quantity of it. Unique identified by an id.
class ResourceSource
  # Unique identifier of resource source
  attr_accessor :id

  # {Cosmos::Resource} contained in entity
  attr_accessor :resource

  # Numerical quantity of resource contained in entity
  attr_accessor :quantity

  # Entity containing the resource
  attr_accessor :entity

  # Cosmos::ResourceSource intializer
  # @param [Hash] args hash of options to initialize resource_source with
  # @option args [String] :id,'id' unqiue identifier to assign to the resource_source
  # @option args [Cosmos::Resource] :resource,'resource' resource which to assign to resource_source
  # @option args [Integer] :quantity,'quantity' amount of resource present in resource_source
  # @option args [CosmosEntity] :entity,'entity' cosmos entity containing the resource
  def initialize(args = {})
    @id       = args[:id]         || args['id']         || Motel::gen_uuid
    @resource = args['resource']  || args[:resource]
    @quantity = args['quantity']  || args[:quantity]
    @entity   = args['entity']    || args[:entity]
  end

  # Convert resource_source to human readable string and return it
  def to_s
    "resource_source-#{@id}-(#{@quantity} of #{resource.id} at #{entity.name})"
  end

  # Convert resource_source to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :resource => resource, :quantity => quantity, :entity => entity}
    }.to_json(*a)
  end

  # Create new resource_source from json representation
  def self.json_create(o)
    rs = new(o['data'])
    return rs
  end
end

end
