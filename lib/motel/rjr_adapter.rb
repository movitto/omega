# Motel rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'
require 'rjr/dispatcher'

module Motel

class RJRAdapter
  def self.init
    self.register_handlers(RJR::Dispatcher)
    Motel::Runner.instance.start :async => true
    @@remote_location_manager = RemoteLocationManager.new
  end

  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('get_all_locations') {
       Users::Registry.require_privilege(:privilege => 'view', :entity => 'locations',
                                         :session   => @headers['session_id'])
       Runner.instance.locations
    }

    rjr_dispatcher.add_handler('get_location') { |location_id|
       loc = Runner.instance.locations.find { |loc| loc.id == location_id }
       # TODO pull in remote location if loc.remote_queue is set
       raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?

       if loc.restrict_view
         Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                    {:privilege => 'view', :entity => 'locations'}],
                                           :session => @headers['session_id'])
       end

       # traverse and pull in children managed by remote trackers
       loc.each_child { |rparent, rchild|
         if rchild.remote_queue
           remote_child = @@remote_location_manager.get_location(rchild)

           # swap child for remote_child
           # we lose attributes of original child's not sent over rjr
           # TODO just update rchild ?
           rparent.remove_child(rchild.id)
           rparent.add_child(remote_child)
         end
       }

       loc
    }

    rjr_dispatcher.add_handler('get_locations_within_proximity') { |location, max_distance|
      locations = Runner.instance.locations.select { |loc|
        (loc.parent_id == location.parent_id) &&
        (loc - location) <= max_distance
      }
      locations.reject! { |loc|
        loc.restrict_view &&
        !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                  {:privilege => 'view', :entity => 'locations'}],
                                         :session => @headers['session_id'])
      }


       locations.each { |loc|
         loc.each_child { |rparent, rchild|
           if rchild.remote_queue
             remote_child = @@remote_location_manager.get_location(rchild)

             # swap child for remote_child
             # we lose attributes of original child's not sent over rjr
             # TODO just update rchild ?
             rparent.remove_child(rchild.id)
             rparent.add_child(remote_child)
           end
         }
       }

       locations
    }

    rjr_dispatcher.add_handler('create_location') { |*args|
       Users::Registry.require_privilege(:privilege => 'create', :entity => 'locations',
                                         :session   => @headers['session_id'])

       location = args.size == 0 ? Location.new : args[0]
       #location = Location.new location if args[0].is_a? Hash

       unless location.parent_id.nil?
         parent = Runner.instance.locations.find { |loc| loc.id == location.parent_id }
         parent.add_child(location) unless parent.nil?
         location.parent = parent
       end

       location.x = 0 if location.x.nil?
       location.y = 0 if location.y.nil?
       location.z = 0 if location.z.nil?

       if location.remote_queue
         @@remote_location_manager.create_location(location)
       end

       Runner.instance.run location unless Runner.instance.has_location?(location.id)

       location
    }

    rjr_dispatcher.add_handler("update_location") { |location|
       rloc = Runner.instance.locations.find { |loc| loc.id == location.id  }
       raise Omega::DataNotFound, "location specified by #{location.id} not found" if rloc.nil?

       if rloc.restrict_modify
         Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "location-#{rloc.id}"},
                                                    {:privilege => 'modify', :entity => 'locations'}],
                                           :session   => @headers['session_id'])
       end

       # store the old location coordinates for comparison after the movement
       old_coords = [location.x, location.y, location.z]

       # adjust location heirarchy
       if (rloc.parent_id != location.parent_id)
         new_parent = Runner.instance.locations.find { |loc| loc.id == location.parent_id  }
         new_parent.add_child(rloc) unless new_parent.nil?
       end
       location.parent = rloc.parent

       # client should explicity set movement_strategy on location to nil to keep movement strategy
       # FIXME this should halt location movement, update location, then start it again
       RJR::Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
       rloc.update(location)

       # TODO if rloc.remote_queue != location.remote_queue, move ?
       if rloc.remote_queue
         @@remote_location_manager.update_location(rloc)
       end

       # invoke callbacks as appropriate
       #rloc.movement_callbacks.each { |callback|
       #  callback.invoke(rloc, *old_coords)
       #}
       #rloc.proximity_callbacks.each { |callback|
       #  callback.invoke(rloc)
       #}

       location
    }

    rjr_dispatcher.add_handler('track_movement') { |location_id, min_distance|
       loc = Runner.instance.locations.find { |loc| loc.id == location_id }
       raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?


       on_movement = 
         Callbacks::Movement.new :endpoint => @headers['source_node'],
                                 :min_distance => min_distance,
                                 :handler => lambda{ |loc, d, dx, dy, dz|
           begin
             if loc.restrict_view
               Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                          {:privilege => 'view', :entity => 'locations'}],
                                                 :session   => @headers['session_id'])
             end
             @rjr_callback.invoke('on_movement', loc)

           rescue Omega::PermissionError => e
             RJR::Logger.warn "client does not have privilege to view movement of #{loc.id}"
             loc.movement_callbacks.delete on_movement

           # FIXME connection error will only trigger when movement
           # callback is triggered, need to detect connection being
           # terminated whenever it happens
           rescue RJR::Errors::ConnectionError => e
             RJR::Logger.warn "track_movement client disconnected"
             loc.movement_callbacks.delete on_movement
           end
         }
       # TODO this ignores distance differences, do anything about this?
       old = loc.movement_callbacks.find { |m| m.endpoint_id == on_movement.endpoint_id }
       unless old.nil?
         loc.movement_callbacks.delete(old)
       end

       loc.movement_callbacks << on_movement
       loc
    }

    rjr_dispatcher.add_handler('track_proximity') { |location1_id, location2_id, event, max_distance|
       loc1 = Runner.instance.locations.find { |loc| loc.id == location1_id }
       loc2 = Runner.instance.locations.find { |loc| loc.id == location2_id }
       raise Omega::DataNotFound, "location specified by #{location1_id} not found" if loc1.nil?
       raise Omega::DataNotFound, "location specified by #{location2_id} not found" if loc2.nil?

       on_proximity =
         Callbacks::Proximity.new :endpoint => @headers['source_node'],
                                  :to_location => loc2,
                                  :event => event,
                                  :max_distance => max_distance,
                                  :handler => lambda { |location1, location2|
           begin
             if loc1.restrict_view
               Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc1.id}"},
                                                          {:privilege => 'view', :entity => 'locations'}],
                                               :session   => @headers['session_id'])
             end

             if loc2.restrict_view
               Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc2.id}"},
                                                        {:privilege => 'view', :entity => 'locations'}],
                                               :session   => @headers['session_id'])
             end

             @rjr_callback.invoke('on_proximity', loc1, loc2)

           rescue Omega::PermissionError => e
             RJR::Logger.warn "client does not have privilege to view proximity of #{loc1.id}/#{loc2.id}"
             loc1.proximity_callbacks.delete on_proximity
           rescue RJR::Errors::ConnectionError => e
             RJR::Logger.warn "track_proximity client disconnected"
             loc1.proximity_callbacks.delete on_proximity
           end
         }

       old = loc1.proximity_callbacks.find { |p| p.endpoint_id == on_proximity.endpoint_id }
       unless old.nil?
         loc1.proximity_callbacks.delete(old)
       end

       loc1.proximity_callbacks << on_proximity
       [loc1, loc2]
    }

    rjr_dispatcher.add_handler('remove_callbacks') { |*args|
      location_id = args[0]
      callback_type = args.length > 1 ? args[1] : nil
      source_node = @headers['source_node']
      # FIXME verify request is coming from authenticated source node

      loc = Runner.instance.locations.find { |loc| loc.id == location_id }
      raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                 {:privilege => 'view', :entity => 'locations'}],
                                        :session   => @headers['session_id'])

      if callback_type.nil? || callback_type == 'movement'
        loc.movement_callbacks.reject!{ |mc| mc.endpoint_id == source_node }
      end

      if callback_type.nil? || callback_type == 'proximity'
        loc.proximity_callbacks.reject!{ |mc| mc.endpoint_id == source_node }
      end
      loc
    }

    rjr_dispatcher.add_handler('motel::save_state') { |output|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      output_file = File.open(output, 'a+')
      Runner.instance.save_state(output_file)
      output_file.close
      nil
    }

    rjr_dispatcher.add_handler('motel::restore_state') { |input|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      input_file = File.open(input, 'r')
      Runner.instance.restore_state(input_file)
      input_file.close
      nil
    }

  end
end

end # module Motel
