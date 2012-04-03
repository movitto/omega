# Cosmos Resource definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Resource
  attr_accessor :name
  attr_accessor :type

  def initialize(args = {})
    @name = args['name']  || args[:name]
    @type = args['type']  || args[:type]
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:name => name, :type => type}
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
