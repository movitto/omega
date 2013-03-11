# Missions Resources Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Missions
module Events

# An event to populate the specified cosmos entity w/ the specified resource
class PopulateResource < Missions::Event

  # Default quantity of resource that will be added if not specified
  DEFAULT_QUANTITY = 1000

  # Resource which to populate or random
  attr_accessor :resource

  # List of resources which to pick random resource from
  attr_accessor :from_resources

  # Entity which to populate or random
  attr_accessor :entity

  # List of entities which to pick random entity from
  attr_accessor :from_entities

  # Quantity which to populate or random
  attr_accessor :quantity

  # PopulateResource Event Initializer
  def initialize(args = {})
    @resource      = args[:resource]       || args['resource']       || :random
    @entity        = args[:entity]         || args['entity']         || :random
    @quantity      = args[:quantity]       || args['quantity']       || :random
    @from_entities = args[:from_entities]  || args['from_entities']  || []
    @from_resources= args[:from_resources] || args['from_resources'] || []

    @resource = :random if @resource == 'random'
    @entity   = :random if @entity   == 'random'
    @quantity = :random if @quantity == 'random'

    super(args)
    @callbacks.unshift lambda { |e|
      @resource = (@resource == :random ? from_resources[rand(from_resources.size)] : @resource)
      @entity   = (@entity   == :random ? from_entities[rand(from_entities.size)]   : @entity)
      @quantity = (@quantity == :random ? rand(DEFAULT_QUANTITY)                    : @quantity)
      Missions::Event.node.invoke_request('cosmos::set_resource', @entity.id, @resource, @quantity)
    }
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :timestamp => timestamp,:callbacks => callbacks[1..-1],
                       :resource => resource, :entity => entity, :quantity => @quantity,
                       :from_entities => @from_entities, :from_resources => @from_resources}
    }.to_json(*a)
  end
end

end
end
