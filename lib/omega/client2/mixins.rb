# Omega Client Mixins
#   Provide various high level modules which are able to be mixed into
#   classes to incorporate Omega client functionality
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'manufactured/station'

module Omega
  module Client
    # Include the RemotelyTrackable module in classes to associate
    # instances of the class w/ server side entities. The server
    # side entity associated with the RemotelyTrackable instance
    # is determined by various properties set in the class and
    # initialization methods such as the entity_type and id.
    #
    # The actual entities being tracked are not stored here,
    # rather the global Client::Node registry is used
    #
    # @example
    #   class Ship
    #     include RemotelyTrackable
    #
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   Ship.get('ship1')
    module RemotelyTrackable
      # The class methods below will be defined on the
      # class including this module
      #
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # By default all method calls are sent to entity
      # associated with each RemotelyTrackable instance
      def method_missing(method_id, *args, &bl)
        self.entity.send(method_id, *args, &bl)
      end

      # Convert entity being tracked to string and return
      def to_s
        self.entity.to_s
      end

      # Return entity being tracked.
      #
      # @return [Object] entity local copy of server side entity being tracked
      def entity
        Node.get(@entity_id)
      end

      # Set the id of the entity to track.
      #
      # This shouldn't be invoked by the end user
      #
      # @param [String] val id of the entity to track
      def entity_id=(val)
        @entity_id = val
      end

      # Retrieve the entity from the server.
      #
      # Updates the locally tracked copy via the Client::Node subsystem.
      # @return [RemotelyTrackable] returns self
      def get
        Node.invoke_request self.class.get_method, "with_id", @entity_id
        self
      end

      # Register block to be invoked when the specified event is detected
      # for the locally tracked entity.
      #
      # The developer may register additional callbacks to be invoked to
      # run the steps to setup and begin listening for/handling events
      # (if necessary) by invoking ClassMethods#server_event in their class defintion.
      #
      # Each of these setup callbacks are invoked with the additonal args specified to
      # this method
      #
      # @param [Symbol] event event which we are registering handler for
      # @param [Array<Object>] setup_args catch all of optional args to pass to
      #   any registered setup methods
      # @param [Callable] bl callback to be invoked on entity event
      def handle_event(event, *setup_args, &bl)
        event_setup = self.class.instance_variable_get("@event_setup_#{event}".intern)
        # XXX hack
        event_setup = self.class.superclass.instance_variable_get("@event_setup_#{event}".intern) if event_setup.nil?
        event_setup.each { |cb| instance_exec(*setup_args, &cb) } unless event_setup.nil?
        #self.class.instance_variable_set("@event_setup_#{event}".intern, nil)
        Node.add_event_handler self.id, event, &bl
      end

      # Return boolean indicating if handler exists for specified envent
      def has_event_handler?(event)
        Node.has_event_handler? self.id, event
      end

      # Clear the event handlers for the specified event
      def clear_handlers_for(event)
        Node.clear_event_handlers self.id, event
      end

      # Helper method to invoke initialization callbacks in
      # scope of local instance.
      #
      # @scope private
      def invoke_init(&bl)
        instance_exec self, &bl
      end

      private

      # Methods that are defined on the class including 
      # the RemotelyTrackable module
      module ClassMethods
        # Get/set type of server side entity to track.
        # Always returns current entity type and if
        # an arg is specified, that is used to set it.
        #
        # @param [Class] type server side entity class we are tracking
        # @return [Class] server side entity class being tracked
        def entity_type(type=nil)
          if type.nil?
            return @entity_type unless @entity_type.nil?
            return self.superclass.entity_type unless self.superclass == Object
            return nil
          end
          @entity_type = type
        end

        # Register a method to be invoked after serverside entit(y|ies)
        # are retrieved to perform additional client side verification
        # of the entity type.
        #
        # @example
        #   class MiningShip
        #     include RemotelyTrackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #     entity_validation { |e| e.type == :miner }
        #   end
        #
        # @param [Callable] bl block to invoke w/ entity to validate it
        def entity_validation(&bl)
          # TODO allow registration of multiple methods
          @entity_validation = bl
        end

        # Register a method to be invoked after instance of this class
        # is created by local mechanisms.
        #
        # For this reason, when using RemotelyTrackable, instances of
        # the class including it should only be created through the
        # instantiation methods defined here.
        #
        # @param [Callable] bl block to invoke w/ entity after it is initialized
        def on_init(&bl)
          @entity_init ||= []
          @entity_init << bl
        end

        # Get/set the method used to retrieve serverside entities.
        # Will always return method name. If argument is given, used
        # to set new value
        #
        # @param [String] method_name name of method to register
        # @return [String] name of method used to retrieve server entities
        def get_method(method_name=nil)
          if method_name.nil?
            return @get_method unless @get_method.nil?
            return self.superclass.get_method unless self.superclass == Object
            return nil
          end
          @get_method = method_name
        end

        # Define an event on this entity type which clients can register
        # handlers for specific entity instances.
        #
        # TODO 'server_event' is misleading as the client can raise events
        # using this subsystem, rename this
        #
        # @example
        #   class MiningShip
        #     include RemotelyTrackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #
        #     server_event       :resource_collected => { :subscribe    => "manufactured::subscribe_to",
        #                                                 :notification => "manufactured::event_occurred" },
        #
        #                        :mining_stopped     => { :subscribe    => "manufactured::subscribe_to",
        #                                                 :notification => "manufactured::event_occurred" },
        #
        #                        :movement           => { :setup        => lambda { |distance| Node.invoke_request("motel::track_movement", self.location.id, distance) }
        #                                                 :notification => "motel::on_movement" }
        #   end
        #
        # @param [Hash<Symbol,Hash>] events events to register with the local tracker.
        #   The keys of this hash should correspond to the event identifiers with the
        #   values corresponding to hashes of options as elaborated below:
        # @option events [Callable] :setup method to be invoked w/ entity to
        #   setup / begin listening for / processing events
        # @option events [String] :subscribe server method to invoke to being listening
        #   for event. A setup method will be added to invoke this method when the client
        #   registers a callback for this event. The entity id and event id are passed
        #   as parameters to the subscribe method
        # @option  events [String] :notification local rjr method invoked by server
        #   to notify client event occurred. A setup method will be added to begin
        #   listening for this method when the client registers a callback for the event.
        def server_event(events = {})
          events.keys.each { |e|
            event_setup = []

            if events[e].has_key?(:setup)
              event_setup << events[e][:setup]
            end

            if events[e].has_key?(:subscribe)
              event_setup << lambda { |*args| Node.invoke_request(events[e][:subscribe], self.entity.id, e) }
            end

            if events[e].has_key?(:notification) && !Node.has_method_handler_for?(events[e][:notification])
              event_setup << lambda { |*args|
                Node.add_method_handler(events[e][:notification])
              }
            end

            self.instance_variable_set("@event_setup_#{e}".intern, event_setup)
          }
        end

        # Return array of all server side entities
        # tracked by this class
        #
        # @example
        #   class Ship
        #     include RemotelyTrackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.get_all
        #   # => [<Omega::Client::Ship#...>,<Omega::Client::Ship#...>,...]
        #
        # @return [Array<RemotelyTrackable>] all entities which server returns
        def get_all
          Node.invoke_request(self.get_method, 'of_type', self.entity_type).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        # Return entity tracked by this class corresponding to id,
        # or nil if not found
        #
        # @example
        #   class Ship
        #     include RemotelyTrackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.get('ship1')
        #   # => <Omega::Client::Ship#...>
        #
        # @return [nil,RemotelyTrackable] entity corresponding to id, nil if not found
        def get(id)
          e = track_entity Node.invoke_request(self.get_method, 'with_id', id)
          return nil unless validate_entity(e)
          e
        end

        # Return array of all server side entities
        # tracked by this class owned by the specified user
        #
        # TODO move this into its own module
        #
        # @example
        #   class Ship
        #     include RemotelyTrackable
        #     entity_type Manufactured::Ship
        #     get_method "manufactured::get_entity"
        #   end
        #
        #   Ship.owned_by('Anubis')
        #   # => [<Omega::Client::Ship#...>,<Omega::Client::Ship#...>,...]
        #
        # @return [Array<RemotelyTrackable>] entities owned by specified user which server returns
        def owned_by(user_id)
          Node.invoke_request(self.get_method, 'of_type', self.entity_type, 'owned_by', user_id).
               select  { |e| validate_entity(e) }.
               collect { |e| track_entity(e) }
        end

        private
        # Internal helper to initialize the local class w/ the entity
        # retieved by the server and to invoke init callbacks
        def track_entity(e)
          tracked = self.new
          tracked.entity_id = e.id
          init_entity(tracked)
          tracked
        end

        # Internal helper to invoke init callbacks on entity
        def init_entity(e)
          return if @entity_init.nil?
          @entity_init.each { |init_method|
            e.invoke_init(&init_method)
          }
        end

        # Internal helper to invoke entity validation method on entity
        def validate_entity(e)
          return true if @entity_validation.nil?
          @entity_validation.call(e)
        end


      end
    end

    # Include TrackState in a RemotelyTrackable class to
    # register handlers to be invoked on various custom user defined states
    # of the server side entity.
    #
    # Note is up to the developer to seperate register events and handlers to
    # update the local entity from the server side state
    # @see RemotelyTrackable above
    #
    # @example
    #   class Ship
    #     include RemotelyTrackable
    #     include TrackState
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #
    #     server_state :cargo_full,
    #       :check => lambda { |e| e.cargo_full?       },
    #       :on    => lambda { |e| e.offload_resources },
    #       :off   => lambda { |e|}
    #
    #     def offload_resources
    #       # ...
    #     end
    #   end
    #
    #   Ship.get('ship1').refresh(1) # refreshes ship every second
    module TrackState

      # The class methods below will be defined on the
      # class including this module
      #
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Register handler to be invoked when the entity enters the
      # specified state
      #
      # @param [Symbol] state identifier of the state which to register handler for
      # @param [Callable] bl callback to invoke when entity enters state
      def on_state(state, &bl)
        @on_state_callbacks[state]  ||= []
        @on_state_callbacks[state]  << bl
      end

      # Register handler to be invoked when the entity leaves the
      # specified state
      #
      # @param [Symbol] state identifier of the state which to register handler for
      # @param [Callable] bl callback to invoke when entity leaves state
      def off_state(state, &bl)
        @off_state_callbacks[state] ||= []
        @off_state_callbacks[state] << bl
      end

      #######################################################################
      # these methods are private / used internally

      # This method is invoked by the tracker module when the entity
      # enters the specified state
      #
      # @scope private
      def set_state(state)
        return if @current_states.include?(state) # TODO add flag to disable this check
        @current_states << state
        @on_state_callbacks[state].each { |cb|
          instance_exec self, &cb
        } if @on_state_callbacks.has_key?(state)
      end

      # This method is invoked by the tracker module when the entity
      # leaves the specified state
      #
      # @scope private
      def unset_state(state)
        if(@current_states.include?(state))
          @current_states.delete(state)
          @off_state_callbacks[state].each { |cb|
            instance_exec self, &cb
          } if @off_state_callbacks.has_key?(state)
        end
      end

      # Methods that are defined on the class including 
      # the TrackState module
      module ClassMethods
        # Define a state for this entity type which clients can register
        # on/off handlers for specific entity instances.
        #
        # This method registers a callback to be invoked on entity
        # initialization, integrating the local entity w/ the TrackState module
        # after which an entity updated event handler is registered to detect
        # changes in state
        #
        # All callbacks registered here are invoked in the context of the entity
        # w/ self as the only param
        #
        # @param [Symbol] state entity state which to define
        # @param [Hash<Symbol,Callable>] args callbacks to use during the state lifecycle
        # @option args [Callable] :check callback to invoke to check if the entity is
        #   in the specified state, should return true/false
        # @option args [Callable] :on callback to invoke when entity enters the
        #   specified state
        # @option args [Callable] :off callback to invoke when entity leaves the
        #   specified state
        def server_state(state, args = {})
          on_init { |e|
            @current_states      ||= []
            @on_state_callbacks  ||= {}
            @off_state_callbacks ||= {}

            if args.has_key?(:on)
              on_state(state, &args[:on])
            end

            if args.has_key?(:off)
              off_state(state, &args[:off])
            end

            @condition_checks ||= {}
            if args.has_key?(:check)
              @condition_checks[state] = args[:check]
            end

            return if @handle_state_updates
            @handle_state_updates = true

            e.handle_event('all'){
              #return if @updating_state
              #@updating_state = true
              @condition_checks.each { |st,check|
                if instance_exec(e, &check)
                  e.set_state st
                else
                  e.unset_state st
                end
              }
              #@updating_state = false
            }
          }
        end
      end
    end

    # Include the HasLocation module in classes to associate
    # instances of the class w/ a server side location.
    #
    # @example
    #   class Ship
    #     include RemotelyTrackable
    #     include HasLocation
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   s = Ship.get('ship1')
    #   s.handle_event(:movement) { |sh|
    #     puts "#{sh.id} moved to #{sh.location}"
    #   }
    module HasLocation

      # The class methods below will be defined on the
      # class including this module
      #
      # Defines an event to track entity/location movement
      # which the client may optionally register a handler for
      #
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
        base.server_event :movement =>
          { :setup => lambda { |distance|
              Node.invoke_request("motel::track_movement",
                                  self.location.id, distance)
            },
            :notification => "motel::on_movement"
          }
      end

      # Return latest location tracked by node registry
      #
      # @return [Motel::Location]
      def location
        Node.get(self.entity.location.id)
      end

      # Currently does not define any class methods
      module ClassMethods
      end
    end

    # Include the InSystem module in classes to define
    # various utility methods to perform system-specific
    # movement operations
    #
    # @example
    #   class Ship
    #     include RemotelyTrackable
    #     include HasLocation
    #     include InSystem
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #   end
    #
    #   # issue a server side request to move ship
    #   s = Ship.get('ship1')
    #   s.move_to(:location => Motel::Location.new(:x => 100, :y => 200, :z => -150))
    module InSystem

      # The class methods below will be defined on the
      # class including this module
      #
      # Defines local events that are raised upon stopping
      # the ship and jumping via the client interface
      #
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
        base.server_event :stopped       => {},
                          :jumped        => {}
      end

      # Always return latest system in node registry
      #
      # @return [Cosmos::SolarSystem]
      def solar_system
        Node.get(self.entity.system_name)
      end

      # Return the closest entity of the specified type.
      #
      # *note* this will only search entities in the local registry,
      # it does not currently call out to the server to retrieve entities
      #
      # @param [Symbol] type of entity to retrieve (currently accepts :station, :resource)
      # @param [Hash] args hash of optional arguments to use in lookup
      # @option args [true,false] :user_owned boolean indicating if we should only return
      #   entities owned by the logged in user
      # @return [Array<Object>] entities in local registry matching criteria
      def closest(type, args = {})
        entities = []
        if(type == :station)
          user_owned = args[:user_owned] ? lambda { |eid, e| e.user_id == Node.user.id } :
                                           lambda { |eid, e| true }
          entities = 
            Node.select { |eid,e| e.is_a?(Manufactured::Station) &&
                                  e.location.parent_id == self.location.parent_id }.
                 select(&user_owned).
                 collect { |eid,e| e }.
                 sort    { |a,b| (self.location - a.location) <=>
                                 (self.location - b.location) }

        elsif(type == :resource)
          entities = 
            self.solar_system.asteroids.select { |ast|
              ast.resource_sources.find { |rs| rs.quantity > 0 }
            }.flatten.sort { |a,b|
              (self.location - a.location) <=> (self.location - b.location)
            }
        end

        entities
      end

      # Issue server side call to move entity to specified destination,
      # optionally registering callback to be invoked when it gets there.
      #
      # *note* this will register a movement event callback in addition to
      # any ones previously added / added later
      #
      # @param [Hash<Symbol,Object>] args arguments to used to determine destiantion
      # @option args [Motel::Location] :location exact location to move to
      # @option args [:closest_station,Object] :destination destination to move to
      #   through which location will be inferred / extracted
      # @param [Callable] cb optional callback to be invoked when entity arrives at location
      def move_to(args, &cb)
        # TODO ignore move if we're @ destination
        loc = args[:location]
        if args.has_key?(:destination)
          if args[:destination] == :closest_station
            loc = closest(:station).location
          else
            loc = args[:destination].location
          end
        end

        nloc = Motel::Location.new(:parent_id => self.location.parent_id,
                                   :x => loc.x, :y => loc.y, :z => loc.z)
        clear_handlers_for :movement
        handle_event :movement, (self.location - nloc), &cb unless cb.nil?
        RJR::Logger.info "Moving #{self.id} to #{nloc}"
        Node.invoke_request 'manufactured::move_entity', self.id, nloc
      end

      # Invoke a server side request to stop movement
      def stop_moving
        RJR::Logger.info "Stopping movement of #{self.id}"
        Node.invoke_request 'manufactured::stop_entity', self.id
      end

      # Invoke a server side request to jump to the specified system
      #
      # Raises the :jumped event on entity
      #
      # @param [Cosmos::SolarSystem,Omega::Client::SolarSystem,String] system system or name of system which to jump to
      def jump_to(system)
        if system.is_a?(String)
          ssystem = Node.get(system)
          ssystem = Node.invoke_request('cosmos::get_entity', 'with_name', system) if ssystem.nil?
          system  = ssystem
        end

        loc    = Motel::Location.new
        loc.update self.location
        loc.parent_id = system.location.id
        RJR::Logger.info "Jumping #{self.entity.id} to #{system}"
        Node.invoke_request 'manufactured::move_entity', self.entity.id, loc
        Node.raise_event(:jumped, self)
      end

      # Currently does not define any class methods
      module ClassMethods
      end
    end

    # Include the InteractsWithEnvironment module in classes to define
    # various utility classes to perform many various
    # server side operations.
    #
    # At some point these will most likely be split
    # out into seperate modules
    #
    # @example
    #   class MiningShip
    #     include RemotelyTrackable
    #     include HasLocation
    #     include InSystem
    #     include InteractsWithEnvironment
    #     entity_type Manufactured::Ship
    #     get_method "manufactured::get_entity"
    #     entity_validation { |e| e.type == :miner }
    #   end
    #
    #   s = MiningShip.get('ship1')
    #   s.mine closest(:resource).first
    module InteractsWithEnvironment

      # The class methods below will be defined on the
      # class including this module
      #
      # @see ClassMethods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Mine the specified resource source.
      #
      # All server side mining restrictions apply, this method does
      # not do any checks b4 invoking start_mining so if server raises
      # a related error, it will be reraised here
      #
      # @param [Cosmos::ResourceSource] resource_source resource to start mining
      def mine(resource_source)
        RJR::Logger.info "Starting to mine #{resource_source.resource.id} at #{resource_source.entity.name} with #{self.id}"

        # handle resource collected of entity.mining quantity, invalidating
        # client side cached copy of resource source
        unless @track_resources
          @track_resources = true
          self.handle_event(:resource_collected) { |*args|
            CachedAttribute.invalidate(args[2].entity.id, :resource_sources)
          }
        end

        Node.invoke_request 'manufactured::start_mining',
                   self.id, resource_source.entity.name,
                            resource_source.resource.id

        # XXX hack, mining target won't be set until next iteration
        # of mining cycle loop
        sleep Manufactured::Registry::MINING_POLL_DELAY + 0.1
        self.get
      end

      # Attack the specified target
      #
      # All server side attack restrictions apply, this method does
      # not do any checks b4 invoking attack_entity so if server raises
      # a related error, it will be reraised here
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to attack
      def attack(target)
        RJR::Logger.info "Starting to attack #{target.id} with #{self.id}"
        Node.invoke_request 'manufactured::attack_entity', self.id, target.id

        # XXX hack, do not return until next iteration of attack cycle
        sleep Manufactured::Registry::ATTACK_POLL_DELAY + 0.1
      end

      #def dock(station)
      #end

      #def undock
      #end

      # Transfer all resource sources to target.
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to transfer resources to
      def transfer_all_to(target)
        self.resources.each { |rsid, quantity|
          self.transfer quantity, :of => rsid, :to => target
        }
      end

      # Transfer quantity of specified resource to target.
      #
      # All server side transfer restrictions apply, this method does
      # not do any checks b4 invoking transfer_resource so if server raises
      # a related error, it will be reraised here
      #
      # @param [Float,Integer] quantity amount of resource to transfer
      # @param [Hash<Symbol,Object>] args hash describing entity to resnfer
      # @option args [String] :of id of resource to transfer
      # @option args [Manufactured::Ship,Manufactured::Station] :to target entity to transfer resources to
      def transfer(quantity, args = {})
        resource_id = args[:of]
        target      = args[:to]

        RJR::Logger.info "Transferring #{quantity} of #{resource_id} from #{self.id} to #{target.id}"
        Node.invoke_request 'manufactured::transfer_resource',
                     self.id, target.id, resource_id, quantity
        Node.raise_event(:transferred, self,   target, resource_id, quantity)
        Node.raise_event(:received,    target, self,   resource_id, quantity)
      end

      # Collect specified loot
      #
      # @param [Manufactured::Loot] loot loot which to collect
      def collect_loot(loot)
        RJR::Logger.info "Entity #{self.id} collecting loot #{loot.id}"
        Node.invoke_request 'manufactured::collect_loot', self.id, loot.id
      end

      # Construct the specified entity on the server
      #
      # All server side construction restrictions apply, this method does
      # not do any checks b4 invoking construct_entity so if server raises
      # a related error, it will be reraised here
      #
      # Raises the :constructed event on self
      #
      # @param [String] entity_type type of entity to construct
      # @param [Hash] args hash of args to be converted to array and passed to
      #   server construction operation verbatim
      def construct(entity_type, args={})
        RJR::Logger.info "Constructing #{entity_type} with #{self.entity.id}"
        constructed = Node.invoke_request 'manufactured::construct_entity',
                          self.entity.id, entity_type, *(args.to_a.flatten)
        Node.raise_event(:constructed, self.entity, constructed)
        constructed
      end

      # Currently does not define any class methods
      module ClassMethods
      end
    end

  end
end
