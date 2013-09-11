# Omega Server Proxy Entity definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/registry'

module Omega
module Server

# Omega Proxy Entity, protects entity access using a registry
class ProxyEntity
  instance_methods.each { |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

  def initialize(entity, registry)
    @entity = entity
    @registry = registry
  end

  protected

  def method_missing(name, *args, &block)
    ret = nil
    old_entity = nil
    @registry.safe_exec { |entities|
      old_entity = JSON.parse(@entity.to_json)
      ret = @entity.send(name, *args, &block)
    }
    # TODO only invoke if entity changed?
    @registry.raise_event(:updated, @entity, old_entity)
    ret
  end
end

end # module Server
end # module Omega
