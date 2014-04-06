# Omega Server DSL events operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Server
    module DSL
      # Helper to delete event handler in registry for event/endpoint
      def delete_event_handler_for(args={})
        event_id    = args[:event_id]
        event_type  = args[:event_type]
        endpoint_id = args[:endpoint_id]
        registry    = args[:registry]
      
        registry.delete { |entity|
          entity.is_a?(Omega::Server::EventHandler) &&
          (event_id.nil?   || entity.event_id   == event_id) &&
          (event_type.nil? || entity.event_type == event_type) &&
          entity.endpoint_id == endpoint_id
        }
      end

      # Remove callbacks matching the specified criteria.
      # All criteria are optional and may include
      #   - class : class of entities to look for
      #   - id : id of entity to remove callbacks for
      #   - type : event type to match
      #   - endpoint : rjr endpoint to match
      #
      # XXX Supports both cases where callbacks is a hash or array
      # for different subsystems, these probably should be consolidated
      # at some point
      def remove_callbacks_for(registry_entities, criteria={})
        # allow user to specify registry or entities list
        if registry_entities.kind_of?(Omega::Server::Registry)
          registry_entities.safe_exec { |entities|
            remove_callbacks_for(entities, criteria)
          }
      
          return
        else
          entities = registry_entities
          entities = [entities] unless entities.is_a?(Array)
      
        end
      
        # retrieve entities
        matched = entities.select { |e|
          !criteria.has_key?(:class) || e.is_a?(criteria[:class])
        }
      
        # if specified only operate on single entity
        matched.reject! { |m|
          m.id != criteria[:id]
        } if criteria.has_key?(:id)

      
        matched.each { |m|
          to_remove = []
          (m.callbacks.is_a?(Hash) ? m.callbacks.values.flatten :
                                     m.callbacks).each     { |cb|
      
            # skip if cb event type is specified and does not match
              # skip if cb endpoint id is specified and does not match
            if (!criteria.has_key?(:endpoint)           ||
                 criteria[:endpoint] == cb.endpoint_id) &&
               (!criteria.has_key?(:type)               ||
                 criteria[:type] == cb.event_type)
              to_remove << cb
            end
          }
      
          # remove flagged callbacks, compress array
          to_remove.each { |cb|
            m.callbacks.is_a?(Hash) ? m.callbacks[cb.event_type].delete(cb) :
                                      m.callbacks.delete(cb)
          }
      
          # compress callback list
          if m.callbacks.is_a?(Hash)
            m.callbacks.keys.each { |type|
              m.callbacks[type].compact!
              m.callbacks.delete(type) if m.callbacks[type].empty?
            }
          else
            m.callbacks.compact!
          end
        }
      end

      # Helper to handle node closed event
      def handle_node_closed(node, &cb)
        # delete callback on connection events
# FIXME skip if closed event is already registered for this node
        node.on(:closed){ |node|
          cb.call(node)
        }
      end
    end # module DSL
  end # module Server
end # module Omega
