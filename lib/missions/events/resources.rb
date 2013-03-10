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

  # PopulateResource Event Initializer
  def initialize(args = {})
    @resource      = args[:resource]       || args['resource']       || :random
    @entity        = args[:entity]         || args['entity']         || :random
    @quantity      = args[:quantity]       || args['quantity']       || :random
    from_entities  = args[:from_entities]  || args['from_entities']  || []
    from_resources = args[:from_resources] || args['from_resources'] || []

    if @resource.nil? || @resource == :random
      @resource = from_resources[rand(from_resources.size)]
    end

    if @entity.nil? || @entity == :random
      @entity = from_entities[rand(from_entities.size)]
    end

    if @quantity.nil? || @quantity == :random
      @quantity = DEFAULT_QUANTITY
    end

    super(args)
    @callbacks << lambda { |e|
      Missions::Event.node.invoke_request 'cosmos::set_resource', @entity.id, @resource, @quantity)
    }
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :timestamp => timestamp,:callbacks => callbacks,
                       :resource => resource, :entity => entity}
    }.to_json(*a)
  end
end

end
end
