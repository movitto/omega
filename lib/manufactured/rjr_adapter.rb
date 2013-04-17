# Manufactured rjr adapter
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'active_support/inflector'

# TODO alot of invoke_request calls can be swapped w/ send_notification calls (and in other modules)

module Manufactured

# Provides mechanisms to invoke Manufactured subsystem functionality remotely over RJR.
#
# Do not instantiate as interface is defined on the class.
class RJRAdapter

  class << self
    # @!group Config options

    # User to use to communicate w/ other modules over the local rjr node
    attr_accessor :manufactured_rjr_username

    # Password to use to communicate w/ other modules over the local rjr node
    attr_accessor :manufactured_rjr_password

    # Set config options using Omega::Config instance
    #
    # @param [Omega::Config] config object containing config options
    def set_config(config)
      self.manufactured_rjr_username  = config.manufactured_rjr_user
      self.manufactured_rjr_password  = config.manufactured_rjr_pass
    end

    # @!endgroup
  end

  # Return user which can invoke privileged manufactured operations over rjr
  #
  # First instantiates user if it doesn't exist.
  def self.user
    @@manufactured_user ||= Users::User.new(:id       => Manufactured::RJRAdapter.manufactured_rjr_username,
                                            :password => Manufactured::RJRAdapter.manufactured_rjr_password)
  end

  # Initialize the Manufactured subsystem and rjr adapter.
  def self.init
    Manufactured::Registry.instance.init
    self.register_handlers(RJR::Dispatcher)
    @@local_node = RJR::LocalNode.new :node_id => 'manufactured'
    @@local_node.message_headers['source_node'] = 'manufactured'
    @@local_node.invoke_request('users::create_entity', self.user)
    role_id = "user_role_#{self.user.id}"
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'modify', 'cosmos_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'create', 'locations')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'users_entities')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'user_attributes')
    @@local_node.invoke_request('users::add_privilege', role_id, 'modify', 'user_attributes')
    @@local_node.invoke_request('users::add_privilege', role_id, 'view',   'locations')
    @@local_node.invoke_request('users::add_privilege', role_id, 'modify', 'locations')
    @@local_node.invoke_request('users::add_privilege', role_id, 'create', 'manufactured_entities')

    session = @@local_node.invoke_request('users::login', self.user)
    @@local_node.message_headers['session_id'] = session.id
  end

  # Register handlers with the RJR::Dispatcher to invoke various manufactured operations
  #
  # @param rjr_dispatcher dispatcher to register handlers with
  def self.register_handlers(rjr_dispatcher)
    rjr_dispatcher.add_handler('manufactured::create_entity'){ |entity|
      Users::Registry.require_privilege(:privilege => 'create', :entity => 'manufactured_entities',
                                        :session   => @headers['session_id'])

      valid_types = Manufactured::Registry.instance.entity_types
      raise ArgumentError, "Invalid #{entity.class} entity specified, must be one of #{valid_types.inspect}" unless valid_types.include?(entity.class)

      # swap out the parent w/ the one stored in the cosmos registry
      if entity.parent
        parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_name', entity.parent.name)
        raise Omega::DataNotFound, "parent system specified by #{entity.parent.name} not found" if parent.nil?
        # TODO parent.can_add?(entity)
        Manufactured::Registry.instance.safely_run {
          entity.parent = parent
        }
      end

# FIXME race condition if entity is created elsewhere after this call but before adding to registry below
      rentity = Manufactured::Registry.instance.find(:id => entity.id,
                                                     :include_graveyard => true).first
      raise ArgumentError, "#{entity.class} with id #{entity.id} already taken" unless rentity.nil?

      user = @@local_node.invoke_request('users::get_entity', 'with_id', entity.user_id)
      raise Omega::DataNotFound, "user specified by #{entity.user_id} not found" if user.nil?

      # XXX hack - give new stations enough resources
      # to construct a preliminary helper
      entity.resources['metal-steel'] = 100 if entity.is_a?(Manufactured::Station)

      # ensure user can own another entity (also subject to race condition, see above)
      n = Manufactured::Registry.instance.find(:user_id => entity.user_id).size
      can_create = @@local_node.invoke_request('users::has_attribute?',
                                               entity.user_id,
                                               Users::Attributes::NumberOfEntities.id,
                                               n + 1)
      raise Omega::PermissionError, "User #{entity.user_id} cannot own any more entities (max #{n})" unless can_create

      eloc = nil

      unless entity.location.nil?
        # needs to happen b4 create_location so motel sets up heirarchy correctly
        entity.location.parent_id = entity.parent.location.id if entity.parent
        # creation of location needs to happen before creation of entity
        eloc = @@local_node.invoke_request('motel::create_location', entity.location)
        # needs to happen after create_location as parent won't be sent in the result
        entity.location.parent    = entity.parent.location if entity.parent
      end

      rentity = Manufactured::Registry.instance.create(entity) { |e|
        e.location = eloc
      }

      #if rentity.nil? && !eloc.nil? # FIXME need to delete the location from motel

      # add permissions to view & modify entity to owner
      @@local_node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'view',   "manufactured_entity-#{entity.id}" )
      @@local_node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'modify', "manufactured_entity-#{entity.id}" )
      @@local_node.invoke_request('users::add_privilege', "user_role_#{user.id}", 'view',   "location-#{entity.location.id}" )

      rentity
    }

    # entity will be constructed immediately but will not be available for use
    # until it is processed by the registry construction cycle
    rjr_dispatcher.add_handler('manufactured::construct_entity') { |manufacturer_id, entity_type, *args|
      station = Manufactured::Registry.instance.find(:type => "Manufactured::Station", :id => manufacturer_id).first
      raise Omega::DataNotFound, "station specified by #{manufacturer_id} not found" if station.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # simply convert remaining args into key /
      # value pairs to pass into construct
      argsh = Hash[*args]

      # remove params which should not be set by the user
      # location is validated / modified in station.construct so no need to manipulate here
      ['solar_system','user_id', 'hp',
       'mining', 'attacking', 'cargo_capacity', 'resources', 'notifications',
       'current_shield_level', 'docked_at', 'size'].each { |i| # set docked at to station?
        argsh.delete(i)
      }

      # auto-set additional params
      argsh[:entity_type] = entity_type
      argsh[:solar_system] = station.solar_system
      argsh[:user_id] = Users::Registry.current_user(:session => @headers['session_id']).id # TODO set permissions on entity? # TODO change to station's owner ?

      # TODO also check construction related user attributes (construction class, parallel construction)

      entity = nil

      completed_callback =
        Callback.new(:construction_complete, :endpoint => @@local_node.message_headers['source_node']){ |*args|
          # XXX unsafely run hack needed as callback will be invoked within
          # registry lock and create_entity will also attempt to obtain lock
          Manufactured::Registry.instance.unsafely_run {
            station.notification_callbacks.delete(completed_callback)

            # FIXME how to handle if create_entity fails for whatever reason?
            @@local_node.invoke_request('manufactured::create_entity', entity)
          }
        }

      Manufactured::Registry.instance.safely_run {
        station.clear_errors :of_type => :construction
        unless station.can_construct?(argsh)
          raise ArgumentError,
                "station specified by #{station} "\
                "cannot construct entity with args #{args.inspect} "\
                "due to errors: #{station.errors[:construction]} "
        end

        # create the entity and return it
        entity = station.construct argsh

        # track delayed station construction
        station.notification_callbacks << completed_callback
      }

      raise ArgumentError, "could not construct #{entity_type} at #{station} with args #{args.inspect}" if entity.nil?

      # schedule construction / placement in system in construction cycle
      Manufactured::Registry.instance.schedule_construction :station => station, :entity => entity

      # Return station and constructed entity
      [station, entity]
    }

    rjr_dispatcher.add_handler(['manufactured::get', 'manufactured::get_entity', 'manufactured::get_entities']){ |*args|
       filter = {}
       # TODO also include_graveyard option?
       while qualifier = args.shift
         raise ArgumentError, "invalid qualifier #{qualifier}" unless ["of_type", "owned_by", "with_id", "with_location", "under", "include_loot"].include?(qualifier)
         val = args.shift
         raise ArgumentError, "qualifier #{qualifier} requires value" if val.nil?
         qualifier = case qualifier
                       when "of_type"
                         :type
                       when "owned_by"
                         :user_id
                       when "with_id"
                         :id
                       when "with_location"
                         :location_id
                       when "under"
                         :parent_id
                       when "include_loot"
                         :include_loot
                     end
         filter[qualifier] = val
       end

       # if user specified id or location, return the first (and only) result on its own
       return_first = filter.has_key?(:id) || filter.has_key?(:location_id)

       # ensure user exists if user_id is specified
       if filter.has_key?(:user_id)
         user = @@local_node.invoke_request('users::get_entity', 'with_id', filter[:user_id])
         raise Omega::DataNotFound, "user specified by #{user_id} not found" if user.nil?
       end

       # ensure system exists if parent_id is specified
       if filter.has_key?(:parent_id)
         parent = @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_name', filter[:parent_id])
         raise Omega::DataNotFound, "parent system specified by #{parent_id} not found" if parent.nil?
       end

       entities = Manufactured::Registry.instance.find(filter)

       entities.reject! { |entity|
         !Users::Registry.check_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                   {:privilege => 'view', :entity => 'manufactured_entities'}],
                                          :session => @headers['session_id'])

       }

       entities.each { |entity|
         Manufactured::Registry.instance.safely_run {
           entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
         }
       }

       if return_first
         entities = entities.first
         raise Omega::DataNotFound, "manufactured entity specified by #{filter} not found" if entities.nil?
       end

       entities
    }

    rjr_dispatcher.add_handler('manufactured::subscribe_to') { |entity_id, event|
      entity = Manufactured::Registry.instance.find(:id => entity_id).first
      raise Omega::DataNotFound, "manufactured entity specified by #{entity_id} not found" if entity.nil?

      # TODO add option to verify request is coming from authenticated source node which current connection was established on
      # TODO ensure that rjr_node_type supports persistant connections

      event_callback =
        Callback.new(event, :endpoint => @headers['source_node']){ |*args|
          begin
            Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                       {:privilege => 'view', :entity => 'manufactured_entities'}],
                                              :session => @headers['session_id'])
            @rjr_callback.invoke 'manufactured::event_occurred', *args

          rescue Omega::PermissionError => e
            # FIXME delete all entity.notification_callbacks associated w/ @headers['session_id']
            RJR::Logger.warn "client does not have privilege to subscribe to #{event} on #{entity.id}"
            entity.notification_callbacks.delete event_callback

          # FIXME @rjr_node.on(:closed){ |node| entity.notification_callbacks.delete event_callback }
          rescue RJR::Errors::ConnectionError => e
            RJR::Logger.warn "subscribe_to client disconnected"
            entity.notification_callbacks.delete event_callback
          end
        }

      Manufactured::Registry.instance.safely_run {
        old = entity.notification_callbacks.find { |n| n.type == event_callback.type &&
                                                       n.endpoint_id == event_callback.endpoint_id }

        unless old.nil?
         entity.notification_callbacks.delete(old)
        end

        entity.notification_callbacks << event_callback
      }

      entity
    }

    rjr_dispatcher.add_handler('manufactured::remove_callbacks') { |entity_id|
      source_node = @headers['source_node']
      # TODO add option to verify request is coming from authenticated source node which current connection was established on

      entity = Manufactured::Registry.instance.find(:id => entity_id, :include_graveyard => true).first
      raise Omega::DataNotFound, "entity specified by #{entity_id} not found" if entity.nil?
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      Manufactured::Registry.instance.safely_run {
        entity.notification_callbacks.reject!{ |nc| nc.endpoint_id == source_node }
      }

      entity
    }

    # adds the specified resource to the specified entity,
    # XXX would rather not have but needed by other subsystems
    rjr_dispatcher.add_handler('manufactured::add_resource'){ |entity_id, resource_id, quantity|
      # require local transport
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE

      # require modify manufactured_resources
      # also require modify on the entity ?
      Users::Registry.require_privilege(:privilege => 'modify', :entity => 'manufactured_resources',
                                        :session   => @headers['session_id'])

      entity = Manufactured::Registry.instance.find(:id => entity_id).first
      raise Omega::DataNotFound, "manufactured entity specified by #{entity_id} not found"  if entity.nil?

      raise ArgumentError, "quantity must be an int / float > 0" if (!quantity.is_a?(Integer) && !quantity.is_a?(Float)) || quantity <= 0

      # TODO validate resource_id

      Manufactured::Registry.instance.safely_run {
        entity.add_resource resource_id, quantity
      }

      entity
    }


    rjr_dispatcher.add_handler('manufactured::move_entity'){ |id, new_location|
      entity = Manufactured::Registry.instance.find(:id => id).first
      parent = new_location.parent_id.nil? ? entity.parent : @@local_node.invoke_request('cosmos::get_entity', 'of_type', :solarsystem, 'with_location', new_location.parent_id)

      raise ArgumentError, "invalid location #{new_location} specified" unless new_location.is_a?(Motel::Location)

      raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
      raise Omega::DataNotFound, "parent system specified by location #{new_location.parent_id} not found" if parent.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise exception if entity or parent is invalid
      raise ArgumentError, "Must specify ship or station to move" unless entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)
      raise ArgumentError, "Must specify system to move ship to"  unless parent.is_a?(Cosmos::SolarSystem)

      # TODO may want to incorporate fuel into this at some point

      Manufactured::Registry.instance.safely_run {
        # update the entity's location
        entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))

        # if parents don't match, we are moving entity between systems
        if entity.parent.id != parent.id
          # if moving ship ensure it is within trigger distance of gate to new system and is not docked
          #   (TODO currently stations don't have this restriction though we may want to put others in place, or a transport delay / time)
          # TODO support skipping this check if user has sufficient privs (perhaps modify-manufactured_entities ?)
          if entity.is_a?(Manufactured::Ship)
            near_jg = !entity.solar_system.jump_gates.select { |jg| jg.endpoint.name == parent.name &&
                                                                    (jg.location - entity.location) < jg.trigger_distance }.empty?
            raise Omega::OperationError, "Ship #{entity} not within triggering distance of a jump gate to #{parent}" unless near_jg
            raise Omega::OperationError, "Ship #{entity} is docked, cannot move" if entity.docked?
          end

          # simply set parent and location
          # TODO set new_location x, y, z to vicinity of reverse jump gate (eg gate to current system in destination system) if it exists
          entity.parent   = parent
          new_location.movement_strategy = Motel::MovementStrategies::Stopped.instance
          entity.location.update(new_location)

          @@local_node.invoke_request('motel::update_location', entity.location)
          # TODO why do we remove callbacks? should we remove them all ? or leave them be?
          @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, 'movement')
          @@local_node.invoke_request('motel::remove_callbacks', entity.location.id, 'rotation')

        # else move location within the system
        else
          # if moving ship, ensure it is not docked
          if entity.is_a?(Manufactured::Ship) && entity.docked?
            raise Omega::OperationError, "Ship #{entity} is docked, cannot move"
          end

          dx = new_location.x - entity.location.x
          dy = new_location.y - entity.location.y
          dz = new_location.z - entity.location.z
          distance = new_location - entity.location

          raise Omega::OperationError, "Ship or station #{entity} is already at location" if distance < 1

          # Move to location using a linear movement strategy.
          # If not oriented towards destination (or at least close enough), rotate first, then move
          linear =  Motel::MovementStrategies::Linear.new :direction_vector_x => dx/distance,
                                                          :direction_vector_y => dy/distance,
                                                          :direction_vector_z => dz/distance,
                                                          :speed => entity.movement_speed
          rot_a  = nil
          loc    = nil

          or_diff = entity.location.orientation_difference(*new_location.coordinates)
          entity.next_movement_strategy []

          if or_diff.all? { |od| od.abs < (Math::PI / 8) }
            entity.location.movement_strategy = linear

          else
            rot_a = or_diff[0].abs + or_diff[1].abs
            rotate = Motel::MovementStrategies::Rotate.new :dtheta => (or_diff[0] * entity.rotation_speed / rot_a),
                                                           :dphi   => (or_diff[1] * entity.rotation_speed / rot_a)
            entity.location.movement_strategy = rotate
            entity.next_movement_strategy linear
          end

          entity.next_movement_strategy Motel::MovementStrategies::Stopped.instance
          loc = entity.location

          @@local_node.invoke_request('motel::track_rotation', loc.id,    rot_a) unless rot_a.nil?
          @@local_node.invoke_request('motel::track_movement', loc.id, distance)
          @@local_node.invoke_request('motel::update_location', loc)
        end
      }

      entity
    }

    rjr_dispatcher.add_handler('manufactured::follow_entity'){ |id, target_id, distance|
      raise ArgumentError, "entity #{id} and target #{target_id} cannot be the same" if id == target_id

      entity = Manufactured::Registry.instance.find(:id => id).first
      target_entity = Manufactured::Registry.instance.find(:id => target_id).first

      raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?
      raise Omega::DataNotFound, "manufactured entity specified by #{target_id} not found"  if target_entity.nil?

      raise ArgumentError, "distance must be an int / float > 0" if !distance.is_a?(Integer) && !distance.is_a?(Float) && distance <= 0

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{target_entity.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise exception if entity or target is invalid
      raise ArgumentError, "Must specify ship to move"           unless entity.is_a?(Manufactured::Ship)
      raise ArgumentError, "Must specify ship to follow"         unless target_entity.is_a?(Manufactured::Ship)

      # atomically update the entities
      Manufactured::Registry.instance.safely_run {
        entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
        target_entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', target_entity.location.id))

        # ensure entities are in the same system
        raise ArgumentError, "entity #{entity} must be in the same system as entity to follow #{target_entity}" if entity.location.parent.id != target_entity.location.parent.id

        # ensure entity isn't docked
        raise Omega::OperationError, "Ship #{entity} is docked, cannot move" if entity.docked?

        entity.location.movement_strategy =
          Motel::MovementStrategies::Follow.new :tracked_location_id => target_entity.location.id,
                                                :distance            => distance,
                                                :speed => entity.movement_speed
        @@local_node.invoke_request('motel::update_location', entity.location)
      }

      entity
    }

    rjr_dispatcher.add_handler('manufactured::stop_entity'){ |id|
      entity = Manufactured::Registry.instance.find(:id => id).first

      raise Omega::DataNotFound, "manufactured entity specified by #{id} not found"  if entity.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise exception if entity or parent is invalid
      raise ArgumentError, "Must specify ship or station to move" unless entity.is_a?(Manufactured::Ship) || entity.is_a?(Manufactured::Station)

      Manufactured::Registry.instance.safely_run {
        # update the entity's location
        entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))

        # set entity's movement strategy to stopped
        entity.location.movement_strategy =
          Motel::MovementStrategies::Stopped.instance
        @@local_node.invoke_request('motel::update_location', entity.location)
        # TODO remove_callbacks?
        # TODO stop mining / attack / other operations ?
      }

      entity
    }

    # callback to track_movement and track_rotation in move_entity
    rjr_dispatcher.add_handler(['motel::on_movement', 'motel::on_rotation']) { |loc|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
# FIXME issue here
      entity = Manufactured::Registry.instance.find(:location_id => loc.id,
                                                    :include_graveyard => true).first

      unless entity.nil?
        Manufactured::Registry.instance.safely_run {
          # XXX location may have been updated in the meantime
          entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', entity.location.id))
          entity.location.movement_strategy = entity.next_movement_strategy
          loc = entity.location
          @@local_node.invoke_request('motel::update_location', loc)
          @@local_node.invoke_request('motel::remove_callbacks', loc.id,
                                      @rjr_method == 'motel::on_movement' ? :movement : :rotation)
        }
      end
    }

    rjr_dispatcher.add_handler('manufactured::attack_entity'){ |attacker_entity_id, defender_entity_id|
      raise ArgumentError, "attacker and defender entities must be different" if attacker_entity_id == defender_entity_id

      attacker = Manufactured::Registry.instance.find(:id => attacker_entity_id, :type => "Manufactured::Ship").first
      defender = Manufactured::Registry.instance.find(:id => defender_entity_id, :type => "Manufactured::Ship").first

      raise Omega::DataNotFound, "ship specified by #{attacker_entity_id} (attacker) not found"  if attacker.nil?
      raise Omega::DataNotFound, "ship specified by #{defender_entity_id} (defender) not found"  if defender.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{attacker.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      # FIXME not sure if it's feasible to grant attacker permission to view defender, how to tackle this
      Users::Registry.require_privilege(:any => [{:privilege => 'view', :entity => "manufactured_entity-#{defender.id}"},
                                                 {:privilege => 'view', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # raise error if attacker cannot attack defender
      before_attack_cycle = lambda { |cmd|
        cmd.attacker.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.attacker.location.id))
        cmd.defender.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.defender.location.id))
        raise Omega::OperationError, "#{attacker} cannot attack #{defender}" unless attacker.can_attack?(defender)
      }

      # update locations before attack
      before_attack = lambda { |cmd|
        cmd.attacker.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.attacker.location.id))
        cmd.defender.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.defender.location.id))
      }

      # after destroyed, invoke 'users::set_attribute' to set
      # 'ships_user_destroyed' and 'user_ships_destroyed' user attributes
      after_attack = lambda { |cmd|
        if cmd.defender.hp == 0 && cmd.defender.destroyed_by.id == cmd.attacker.id
          @@local_node.invoke_request('users::update_attribute', cmd.attacker.user_id, Users::Attributes::ShipsUserDestroyed.id, 1)
          @@local_node.invoke_request('users::update_attribute', cmd.defender.user_id, Users::Attributes::UserShipsDestroyed.id, 1)
        end
      }

      cmd = Manufactured::Registry.instance.schedule_attack   :attacker  => attacker,
                                                              :defender  => defender,
                                                              :before    => before_attack,
                                                              :after     => after_attack,
                                                              :first     => before_attack_cycle

      Manufactured::Registry.instance.schedule_shield_refresh :entity    => defender,
                                                              :check_command => cmd

      [attacker, defender]
    }

    # TODO
    # rjr_dispatcher.add_handler('manufactured::stop_attack'){ |attacker_entity_id|

    rjr_dispatcher.add_handler('manufactured::dock') { |ship_id, station_id|
      ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
      station = Manufactured::Registry.instance.find(:id => station_id, :type => 'Manufactured::Station').first

      raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?
      raise Omega::DataNotFound, "manufactured station specified by #{station_id} not found"  if station.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      # anyone can dock at stations?
      #Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{station.id}"},
      #                                           {:privilege => 'modify', :entity => 'manufactured_entities'}],
      #                                  :session => @headers['session_id'])

      Manufactured::Registry.instance.safely_run {
        # update ship / station location
        ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', ship.location.id))
        station.location.udpate(@@local_node.invoke_request('motel::get_location', 'with_id', station.location.id))

        raise Omega::OperationError, "#{ship} cannot dock at #{station}" unless station.dockable?(ship)

        ship.dock_at(station)

        # set ship movement strategy to stopped
        # TODO we may want to set position of ship in proximity of station
        ship.location.movement_strategy = Motel::MovementStrategies::Stopped.instance
        @@local_node.invoke_request('motel::update_location', ship.location)
      }

      ship
    }

    rjr_dispatcher.add_handler('manufactured::undock') { |ship_id|
      ship    = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first

      raise Omega::DataNotFound, "manufactured ship specified by #{ship_id} not found" if ship.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      Manufactured::Registry.instance.safely_run {
        # TODO we may want to require a station's docking clearance at some point
        raise Omega::OperationError, "#{ship} is not docked, cannot undock" unless ship.docked?

        ship.undock
      }

      ship
    }

    rjr_dispatcher.add_handler('manufactured::start_mining') { |ship_id, entity_id, resource_id|
      ship = Manufactured::Registry.instance.find(:id => ship_id,    :type => 'Manufactured::Ship').first
      # TODO how/where to incorporate resource scanning distance & capabilities into this
      resource_sources = @@local_node.invoke_request('cosmos::get_resource_sources', entity_id)
      resource_source  = resource_sources.find { |rs| rs.resource.id == resource_id }

      raise Omega::DataNotFound, "ship specified by #{ship_id} not found" if ship.nil?
      raise Omega::DataNotFound, "resource_source specified by #{entity_id}/#{resource_id} not found" if resource_source.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])


      before_mining_cycle = lambda { |cmd|
        # update ship's location
        cmd.ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.ship.location.id))

        # XXX don't like having to do this but need to load resource source's entity's location parent explicity
        cmd.resource_source.entity.location.parent = @@local_node.invoke_request('motel::get_location', 'with_id', cmd.resource_source.entity.location.parent_id)

        # raise error if miner cannot mine resource
        raise Omega::OperationError, "#{cmd.ship} cannot mine #{cmd.resource_source}" unless ship.can_mine?(cmd.resource_source)

        # remove existing collected/depleted callbacks on local node
        cmd.ship.notification_callbacks.reject!{ |nc| nc.endpoint_id == @@local_node.message_headers['source_node'] &&
                                                      [:mining_stopped, :resource_collected].include?(nc.type) }

        # resource_source is a copy of actual resource_source
        # stored in cosmos registry, wire up callbacks to update original
        collected_callback =
          Callback.new(:resource_collected, :endpoint => @@local_node.message_headers['source_node']){ |*args|
            rs = args[2]
            @@local_node.invoke_request('cosmos::set_resource', rs.entity.name, rs.resource, rs.quantity)
          }
        depleted_callback =
          Callback.new(:mining_stopped, :endpoint => @@local_node.message_headers['source_node']){ |*args|
# FIXME is cmd.ship still a valid reference here?
            cmd.ship.notification_callbacks.delete collected_callback
            cmd.ship.notification_callbacks.delete depleted_callback
          }
        cmd.ship.notification_callbacks << collected_callback
        cmd.ship.notification_callbacks << depleted_callback
      }

      # update location before mining
      before_mining = lambda { |cmd|
        cmd.ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', cmd.ship.location.id))
      }

      Manufactured::Registry.instance.schedule_mining :ship => ship,
                                                      :resource_source => resource_source,
                                                      :before => before_mining,
                                                      :first  => before_mining_cycle
      ship
    }

    # TODO
    #rjr_dispatcher.add_handler('manufactured::stop_mining') { |ship_id|

    rjr_dispatcher.add_handler('manufactured::transfer_resource') { |from_entity_id, to_entity_id, resource_id, quantity|
      raise ArgumentError, "quantity must be an int / float > 0" if (!quantity.is_a?(Integer) && !quantity.is_a?(Float)) || quantity <= 0

      from_entity = Manufactured::Registry.instance.find(:id => from_entity_id).first
      to_entity   = Manufactured::Registry.instance.find(:id => to_entity_id).first
      raise Omega::DataNotFound, "entity specified by #{from_entity_id} not found" if from_entity.nil?
      raise Omega::DataNotFound, "entity specified by #{to_entity_id} not found"   if to_entity.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{from_entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])
      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{to_entity.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # update from & to entitys' location
      Manufactured::Registry.instance.safely_run {
        from_entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', from_entity.location.id))
        to_entity.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', to_entity.location.id))

        raise Omega::OperationError, "source entity cannot transfer resource" unless from_entity.can_transfer?(to_entity, resource_id, quantity)
        raise Omega::OperationError, "destination entity cannot accept resource" unless to_entity.can_accept?(resource_id, quantity)
      }

      entities = Manufactured::Registry.instance.transfer_resource(from_entity, to_entity, resource_id, quantity)
      raise Omega::OperationError, "problem transferring resources from #{from_entity} to #{to_entity}" if entities.nil?
      entities
    }

    rjr_dispatcher.add_handler('manufactured::collect_loot') { |ship_id, loot_id|
      # TODO also allow specification of resource_id / quantity through args

      ship = Manufactured::Registry.instance.find(:id => ship_id, :type => 'Manufactured::Ship').first
      loot = Manufactured::Registry.instance.loot.find { |l| l.id == loot_id }
      raise Omega::DataNotFound, "ship specified by #{ship_id} not found" if ship.nil?
      raise Omega::DataNotFound, "loot specified by #{loot_id} not found" if loot.nil?

      Users::Registry.require_privilege(:any => [{:privilege => 'modify', :entity => "manufactured_entity-#{ship.id}"},
                                                 {:privilege => 'modify', :entity => 'manufactured_entities'}],
                                        :session => @headers['session_id'])

      # update from & to entitys' location
      Manufactured::Registry.instance.safely_run {
        ship.location.update(@@local_node.invoke_request('motel::get_location', 'with_id', ship.location.id))

        # ensure within the transfer distance
        # TODO add a can_collect? method to ship
        raise Omega::OperationError, "ship too far from loot" unless ship.location - loot.location <= ship.transfer_distance

        # TODO also support partial transfers
        raise Omega::OperationError, "ship cannot accept loot" unless ship.can_accept?('', loot.quantity)

        loot.resources.each { |rs,q|
          ship.add_resource(rs, q)
          loot.remove_resource(rs, q)
        }
      }

      # FIXME this is what deletes empty loot, need to uncomment
      # and make atomic w/ loot transfer operation above
      #Manufactured::Registry.instance.set_loot(loot)

      ship
    }

    rjr_dispatcher.add_handler('manufactured::save_state') { |output|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      output_file = File.open(output, 'a+')
      Manufactured::Registry.instance.save_state(output_file)
      output_file.close
    }

    rjr_dispatcher.add_handler('manufactured::restore_state') { |input|
      raise Omega::PermissionError, "invalid client" unless @rjr_node_type == RJR::LocalNode::RJR_NODE_TYPE
      input_file = File.open(input, 'r')
      Manufactured::Registry.instance.restore_state(input_file)
      input_file.close
    }


  end
end # class RJRAdapter

end # module Manufactured
