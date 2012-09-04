# Motel rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/exceptions'
require 'rjr/dispatcher'

module Motel

# Provides mechanisms to invoke Motel subsystem functionality remotely over RJR.
#
# Do not instantiate as interface is defined on the class.
class RJRAdapter
  # Initialize the Motel subsystem and rjr adapter.
  def self.init
    self.register_handlers(RJR::Dispatcher)
    Motel::Runner.instance.start :async => true
    @@remote_location_manager = RemoteLocationManager.new
  end

  # Register handlers with the RJR::Dispatcher to invoke various motel operations
  #
  # @param rjr_dispatcher dispatcher to register handlers with
  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler(['motel::get_location', 'motel::get_locations']) { |*args|
       return_first = false
       filters = []
       while qualifier = args.shift
         raise ArgumentError, "invalid qualifier #{qualifier}" unless ["with_id", "within"].include?(qualifier)
         filter = case qualifier
                    when "with_id"
                      return_first = true
                      val = args.shift
                      raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
                      lambda { |loc| loc.id == val }
                    when "within"
                      distance = args.shift
                      raise ArgumentError, "qualifier #{qualifier} requires int or float distance > 0" if distance.nil? || (!distance.is_a?(Integer) && !distance.is_a?(Float)) || distance <= 0
                      qualifier = args.shift
                      plocation  = args.shift
                      raise ArgumentError, "must specify 'of location' when specifing 'within distance'" if qualifier != "of" || plocation.nil? || !plocation.is_a?(Motel::Location)
                      lambda { |loc| loc.parent_id == plocation.parent_id &&
                                     (loc - plocation) <= distance }
                  end
         filters << filter
       end

       locs = Runner.instance.locations
       filters.each { |f| locs = locs.select &f }

       # TODO pull in remote location if loc.remote_queue is set

       if return_first
         raise Omega::DataNotFound, "location specified by id not found" if locs.empty?
         Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{locs.first.id}"},
                                                    {:privilege => 'view', :entity => 'locations'}],
                                           :session => @headers['session_id']) if locs.first.restrict_view
       end

       locs.reject! { |loc|
         loc.restrict_view &&
         !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                   {:privilege => 'view', :entity => 'locations'}],
                                          :session => @headers['session_id'])
       }

       locs.each { |loc|
         loc.each_child { |rparent, rchild|
           if rchild.remote_queue
             remote_child = @@remote_location_manager.get_location(rchild)

             # swap child for remote_child
             # we lose attributes of original child's not sent over rjr
             # TODO just update rchild ?
             Motel::Runner.instance.safely_run {
               rparent.remove_child(rchild.id)
               rparent.add_child(remote_child)
             }
           end
         }
       }

       return_first ? locs.first : locs
    }

    rjr_dispatcher.add_handler('motel::create_location') { |new_location|
       Users::Registry.require_privilege(:privilege => 'create', :entity => 'locations',
                                         :session   => @headers['session_id'])

       raise ArgumentError, "#{new_location} must be a location" unless new_location.is_a?(Motel::Location)

       unless new_location.parent_id.nil?
         # if parent.nil? throw error?
         parent = Runner.instance.locations.find { |loc| loc.id == new_location.parent_id }
         Motel::Runner.instance.safely_run {
           parent.add_child(new_location) unless parent.nil?
           new_location.parent = parent
         }
       end

       Motel::Runner.instance.safely_run {
         new_location.x = 0 unless new_location.x.is_a?(Integer) || new_location.x.is_a?(Float)
         new_location.y = 0 unless new_location.y.is_a?(Integer) || new_location.y.is_a?(Float)
         new_location.z = 0 unless new_location.z.is_a?(Integer) || new_location.z.is_a?(Float)
         new_location.movement_strategy = Motel::MovementStrategies::Stopped.instance unless new_location.movement_strategy.kind_of?(Motel::MovementStrategy)

         new_location.movement_callbacks  = []
         new_location.proximity_callbacks = []
         new_location.children = []
       }

       if new_location.remote_queue
         @@remote_location_manager.create_location(new_location)
       end

       # id gets set here
       # if id exists, throw error? or invoke update_location?
       Runner.instance.run new_location unless Runner.instance.has_location?(new_location.id)

       new_location
    }

    rjr_dispatcher.add_handler("motel::update_location") { |location|
       raise ArgumentError, "#{location} must be a location with valid id" unless location.is_a?(Motel::Location) && !location.id.nil?

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
         Motel::Runner.instance.safely_run {
           new_parent.add_child(rloc) unless new_parent.nil?
         }
       end

       # setup attributes which should not be overwritten
       location.parent = rloc.parent
       location.remote_queue = rloc.remote_queue
       location.x = 0 unless location.x.is_a?(Integer) || location.x.is_a?(Float)
       location.y = 0 unless location.y.is_a?(Integer) || location.y.is_a?(Float)
       location.z = 0 unless location.z.is_a?(Integer) || location.z.is_a?(Float)
       location.movement_strategy = Motel::MovementStrategies::Stopped.instance unless location.movement_strategy.kind_of?(Motel::MovementStrategy)

       # client should explicity set movement_strategy on location to nil to keep movement strategy
       RJR::Logger.info "updating location #{location.id} with #{location}/#{location.movement_strategy}"
       Motel::Runner.instance.safely_run {
         rloc.update(location)
       }

       # TODO if rloc.remote_queue != location.remote_queue, move ?
       if rloc.remote_queue
         @@remote_location_manager.update_location(rloc)
       end

       # TODO invoke callbacks as appropriate
       #rloc.movement_callbacks.each { |callback|
       #  callback.invoke(rloc, *old_coords)
       #}
       #rloc.proximity_callbacks.each { |callback|
       #  callback.invoke(rloc)
       #}

       location
    }

    rjr_dispatcher.add_handler('motel::track_movement') { |location_id, min_distance|
       loc = Runner.instance.locations.find { |loc| loc.id == location_id }
       raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?

       raise ArgumentError, "min_distance must be an int or float > 0" unless (min_distance.is_a?(Integer) || min_distance.is_a?(Float)) && min_distance > 0

       # TODO add option to verify request is coming from authenticated source node which current connection was established on
       # TODO ensure that rjr_node_type supports persistant connections

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
             @rjr_callback.invoke('motel::on_movement', loc)

           rescue Omega::PermissionError => e
             RJR::Logger.warn "client does not have privilege to view movement of #{loc.id}"
             loc.movement_callbacks.delete on_movement

           rescue RJR::Errors::ConnectionError => e
             RJR::Logger.warn "track_movement client disconnected"
             loc.movement_callbacks.delete on_movement

           rescue Exception => e
             RJR::Logger.warn "exception raised when invoking track_movmement callback: #{e}"
             loc.movement_callbacks.delete on_movement

           end
         }

       @rjr_node.on(:closed){ |node|
         Motel::Runner.instance.safely_run {
           loc.movement_callbacks.delete(on_movement)
         }
       }

       Motel::Runner.instance.safely_run {
         # TODO this ignores distance differences, do anything about this?
         old = loc.movement_callbacks.find { |m| m.endpoint_id == on_movement.endpoint_id }
         unless old.nil?
           loc.movement_callbacks.delete(old)
         end

         loc.movement_callbacks << on_movement
       }

       loc
    }

    rjr_dispatcher.add_handler('motel::track_proximity') { |location1_id, location2_id, event, max_distance|
       loc1 = Runner.instance.locations.find { |loc| loc.id == location1_id }
       loc2 = Runner.instance.locations.find { |loc| loc.id == location2_id }
       raise Omega::DataNotFound, "location specified by #{location1_id} not found" if loc1.nil?
       raise Omega::DataNotFound, "location specified by #{location2_id} not found" if loc2.nil?

       valid_events = ['proximity', 'entered_proximity', 'left_proximity']
       raise ArgumentError, "event must be one of #{valid_events.join(", ")}" unless valid_events.include?(event)
       raise ArgumentError, "max_distance must be an int or float > 0" unless (max_distance.is_a?(Integer) || max_distance.is_a?(Float)) && max_distance > 0

       # TODO add option to verify request is coming from authenticated source node which current connection was established on
       # TODO ensure that rjr_node_type supports persistant connections

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

             @rjr_callback.invoke('motel::on_proximity', loc1, loc2)

           rescue Omega::PermissionError => e
             RJR::Logger.warn "client does not have privilege to view proximity of #{loc1.id}/#{loc2.id}"
             loc1.proximity_callbacks.delete on_proximity

           rescue RJR::Errors::ConnectionError => e
             RJR::Logger.warn "track_proximity client disconnected"
             loc1.proximity_callbacks.delete on_proximity

           rescue Exception => e
             RJR::Logger.warn "exception raised when invoking track_proximity callback: #{e}"
             loc1.proximity_callbacks.delete on_proximity

           end
         }

       @rjr_node.on(:closed){ |node|
         Motel::Runner.instance.safely_run {
           loc1.proximity_callbacks.delete(on_proximity)
         }
       }


       Motel::Runner.instance.safely_run {
         old = loc1.proximity_callbacks.find { |p| p.endpoint_id == on_proximity.endpoint_id }
         unless old.nil?
           loc1.proximity_callbacks.delete(old)
         end

         loc1.proximity_callbacks << on_proximity
       }

       [loc1, loc2]
    }

    rjr_dispatcher.add_handler('motel::remove_callbacks') { |*args|
      location_id = args[0]
      callback_type = args.length > 1 ? args[1] : nil
      source_node = @headers['source_node']
      # TODO add option to verify request is coming from authenticated source node which current connection was established on

      loc = Runner.instance.locations.find { |loc| loc.id == location_id }
      raise Omega::DataNotFound, "location specified by #{location_id} not found" if loc.nil?
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "location-#{loc.id}"},
                                                 {:privilege => 'view', :entity => 'locations'}],
                                        :session   => @headers['session_id'])

      raise ArgumentError, "callback_type must be nil, movement, or proximity" unless [nil, 'movement', 'proximity'].include?(callback_type)

      Motel::Runner.instance.safely_run {
        if callback_type.nil? || callback_type == 'movement'
          loc.movement_callbacks.reject!{ |mc| mc.endpoint_id == source_node }
        end

        if callback_type.nil? || callback_type == 'proximity'
          loc.proximity_callbacks.reject!{ |mc| mc.endpoint_id == source_node }
        end
      }
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
