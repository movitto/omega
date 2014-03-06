# Missions DSL Client Wrapper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'
require 'omega/common'

require 'missions/dsl/helpers'

module Missions
module DSL
module Client

# Client side dsl proxy
#
# Mechanism to allow clients to specify dsl methods to be used in
# server side operations.
#
# Since these dsl methods are not serializable the client sends
# instances of this proxy in place which will be resolved on the server side
class Proxy
  include Helpers

  # Create Proxy instances for DSL methods invoked directly on the class
  def self.method_missing(method_id, *args)
    DSL.constants.each { |c|
      dc = DSL.const_get(c)

      # XXX different dsl categories cannot define methods
      # with the same name, would be nice to resolve this:
      if(dc.methods.include?(method_id))
        return Proxy.new :dsl_category => c.to_s,
                         :dsl_method   => method_id.to_s,
                         :params       => args
      end
    }
    nil
  end

  attr_accessor :dsl_category
  attr_accessor :dsl_method
  attr_accessor :params

  def initialize(args={})
    attr_from_args args, :dsl_category => nil,
                         :dsl_method   => nil,
                         :params       =>  []
  end

  # Resolve all DSL proxies in mission or mission event handler.
  #
  # Pass in the Mission or Missions::EventHandler::DSL instance to resolve
  # proxy reference for. This method will resplace all proxies in the
  # mission / event handler callbacks with their resolved DSL method
  def self.resolve(args={})
    # specify mission or event handler to process
    mission       = args[:mission]
    event_handler = args[:event_handler]

    # Iterate through mission callbacks
    Mission::CALLBACKS.each { |cb|
      dsl_category = dsl_category_for(cb)

      # Retrieve callbacks registered with mission, iterate through arrays
      cbs = mission.send(cb)
      cbs.each_index { |i|

        # Resolve proxy
        if cbs[i].is_a?(Proxy)
          cbs[i] = cbs[i].resolve

        # If proxy specified is a string/symbol, assume it is for the
        # DSL method in the default category for the callback being processed
        elsif cbs[i].is_a?(String)
          proxy = Proxy.new :dsl_category => dsl_category.to_s,
                            :dsl_method   => cbs[i]
          cbs[i] = proxy.resolve

        # If proxy specified is an array, assume first param is the
        # DSL method in the default category for the callback being processed
        elsif cbs[i].is_a?(Array)
          dsl_method = cbs[i].shift
          proxy = Proxy.new :dsl_category => dsl_category.to_s,
                            :dsl_method   => dsl_method,
                            :params       => cbs[i]
          cbs[i] = proxy.resolve
        end
      }
    } if mission

    # Iterated over DSL Event Handler mission callbacks, resolving proxies
    event_handler.missions_callbacks.each_index { |cbi|
      cb = event_handler.missions_callbacks[cbi]
      event_handler.missions_callbacks[cbi] = cb.resolve if cb.is_a?(Proxy)
    } if event_handler
  end

  # Resolve this Proxy instance by invoking the DSL category method
  # with the specified params
  def resolve
    # Retrieve DSL module which to invoke method
    short_category = dsl_category.to_s.demodulize
    return unless is_dsl_category?(short_category)
    dcategory = dsl_module_for(short_category)

    # Retrieve DSL method in module to invoike
    return unless dcategory.has_dsl_method?(dsl_method.to_s)
    dmethod = dcategory.method(dsl_method)

    # Scan through params, call resolve on proxies
    params.each_index { |i|
      param     = params[i]
      params[i] = param.resolve if param.is_a?(Proxy)
    }

    # Invoke DSL method, returning results
    dmethod.call *params
  end

  # Convert Proxy instance to JSON
  def to_json(*a)
     {
       'json_class'     => self.class.name,
       'data'           =>
         {:dsl_category => dsl_category,
          :dsl_method   => dsl_method,
          :params       => params}
     }.to_json(*a)
  end

  # Create new Proxy instance from JSON representation
  def self.json_create(o)
    new(o['data'])
  end
end # class Proxy

# map top level missions dsl modules into client namespace
Requirements = Proxy
Assignment   = Proxy
Event        = Proxy
EventHandler = Proxy
Query        = Proxy
Resolution   = Proxy

end # module Client
end # module DSL
end # module Missions
