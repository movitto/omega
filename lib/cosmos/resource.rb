# Cosmos Resource definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Resource
  attr_accessor :name
  attr_accessor :type

  def initialize(args = {})
    resource = args['resource'] || args[:resource]

    unless resource.nil?
      @name = resource.name
      @type = resource.type
    end

    @name = args['name']  || args[:name] || @name
    @type = args['type']  || args[:type] || @type
  end

  def id
    "#{@type}-#{@name}"
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :name => name, :type => type}
    }.to_json(*a)
  end

  def self.json_create(o)
    rs = new(o['data'])
    return rs
  end
end

class ResourceSource
  attr_accessor :id
  attr_accessor :resource
  attr_accessor :quantity
  attr_accessor :entity

  def initialize(args = {})
    @id       = args[:id]         || args['id']         || Motel::gen_uuid
    @resource = args['resource']  || args[:resource]
    @quantity = args['quantity']  || args[:quantity]
    @entity   = args['entity']  || args[:entity]
  end

  def to_s
    "resource_source-#{@id}-(#{@quantity} of #{resource.id} at #{entity.name})"
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:id => id, :resource => resource, :quantity => quantity, :entity => entity}
    }.to_json(*a)
  end

  def self.json_create(o)
    rs = new(o['data'])
    return rs
  end
end

end
