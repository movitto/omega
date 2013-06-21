# Omega client ship tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO event rate throttling mechanisms:
#   - after threshold only process 1 out of every n events in raise_event
#   - flush queue if max events reached in raise_event
#   - delay new request until events go below threshold in invoke_request
#   - stop running actions on server side until queue is completed, then restart
#   - overwrite pending entity events w/ new events of the same type

require 'omega/client2/mixins'
require 'manufactured'

module Omega
  module Client
    # Omega client Manufactured::Ship tracker
    class Ship
      include RemotelyTrackable
      include HasLocation
      include InSystem
      include InteractsWithEnvironment

      entity_type  Manufactured::Ship

      get_method   "manufactured::get_entity"

      server_event       :defended      => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" },
                         :defended_stop => { :subscribe    => "manufactured::subscribe_to",
                                             :notification => "manufactured::event_occurred" }


      # Mine the specified resource source.
      #
      # All server side mining restrictions apply, this method does
      # not do any checks b4 invoking start_mining so if server raises
      # a related error, it will be reraised here
      #
      # @param [Cosmos::ResourceSource] resource_source resource to start mining
      #def mine(resource_source)
      #  RJR::Logger.info "Starting to mine #{resource_source.resource.id} at #{resource_source.entity.name} with #{self.id}"

      #  # handle resource collected of entity.mining quantity, invalidating
      #  # client side cached copy of resource source
      #  unless @track_resources
      #    @track_resources = true
      #    self.handle_event(:resource_collected) { |*args|
      #      CachedAttribute.invalidate(args[2].entity.id, :resource_sources)
      #    }
      #  end

      #  node.invoke 'manufactured::start_mining',
      #             self.id, resource_source.entity.name,
      #                      resource_source.resource.id

      #  # XXX hack, mining target won't be set until next iteration
      #  # of mining cycle loop
      #  sleep Manufactured::Registry::MINING_POLL_DELAY + 0.1
      #  self.get
      #end

      # Attack the specified target
      #
      # All server side attack restrictions apply, this method does
      # not do any checks b4 invoking attack_entity so if server raises
      # a related error, it will be reraised here
      #
      # @param [Manufactured::Ship,Manufactured::Station] target entity to attack
      #def attack(target)
      #  RJR::Logger.info "Starting to attack #{target.id} with #{self.id}"
      #  Node.invoke_request 'manufactured::attack_entity', self.id, target.id

      #  # XXX hack, do not return until next iteration of attack cycle
      #  sleep Manufactured::Registry::ATTACK_POLL_DELAY + 0.1
      #end

      # Dock at the specified station
      # TODO test
      def dock_to(station)
        RJR::Logger.info "Docking #{self.id} at #{station.id}"
        node.invoke 'manufactured::dock', self.id, station.id
      end

      # Undock
      # TODO test
      def undock
        RJR::Logger.info "Unocking #{self.id}"
        node.invoke 'manufactured::undock', self.id
      end

      # Collect specified loot
      #
      # @param [Manufactured::Loot] loot loot which to collect
      def collect_loot(loot)
        RJR::Logger.info "Entity #{self.id} collecting loot #{loot.id}"
        node.invoke 'manufactured::collect_loot', self.id, loot.id
      end

    end

    # Omega client corvette ship tracker
    #class Corvette < Ship
    #  entity_validation { |e| e.type == :corvette }

    #  server_event       :attacked      => { :subscribe    => "manufactured::subscribe_to",
    #                                         :notification => "manufactured::event_occurred" },
    #                     :attacked_stop => { :subscribe    => "manufactured::subscribe_to",
    #                                         :notification => "manufactured::event_occurred" }

    #  # Run proximity checks via an external thread for all corvettes
    #  # upon first corvette intialization
    #  #
    #  # TODO introduce a centralized entity thread & cycling management system
    #  # in node / mixins and utilize that here
    #  on_init { |corvette|
    #    @@corvettes ||= []
    #    @@corvettes << corvette

    #    @@proximity_thread ||= Thread.new {
    #      while true
    #        @corvettes.each { |c|
    #          c.check_proximity
    #        }
    #        sleep 10
    #      end
    #    }
    #  }

    #  # Start the omega client bot
    #  def start_bot
    #    @visited  = []

    #    self.patrol_route
    #  end

    #  #private

    #  # Internal helper, calculate an inter-system route to patrol
    #  # and move through it.
    #  def patrol_route
    #    # add local system to visited list
    #    @visited << self.solar_system unless @visited.include?(self.solar_system)

    #    # grab jump gate of a neighboring system we haven't visited yet
    #    jg = self.solar_system.jump_gates.find { |jg| !@visited.include?(jg.endpoint) }

    #    # if no items in to_visit clear lists
    #    if jg.nil?
    #      @visited  = []
    #      patrol_route

    #    else
    #      dst = jg.trigger_distance / 4
    #      nl  = jg.location + [dst,dst,dst]
    #      move_to(:location => nl) {
    #        self.jump_to(jg.endpoint)
    #        self.patrol_route
    #      }
    #      
    #    end
    #  end

    #  # Internal helper, check nearby locations, if enemy ship is detected
    #  # stop movement and attack it. Result patrol route when attack ceases
    #  def check_proximity
    #    neighbors = Node.invoke_request 'motel::get_locations',
    #                            'within', self.attack_distance,
    #                                       'of', self.location
    #    neighbors.each { |loc|
    #      begin
    #        sh = Node.invoke_request 'manufactured::get_entity',
    #                            'of_type', 'Manufactured::Ship',
    #                                   'with_location', loc.id
    #        unless sh.nil? || sh.user_id == Node.user.id # TODO respect alliances
    #          self.stop_moving
    #          handle_event(:attacked_stop){ |*args| self.patrol_route }
    #          attack(sh)
    #          break
    #        end
    #      rescue Exception => e
    #      end
    #    }
    #  end
    #end

    ## Omega client miner ship tracker
    #class Miner < Ship
    #  include TrackState

    #  entity_validation { |e| e.type == :mining }

    #  server_event       :resource_collected => { :subscribe    => "manufactured::subscribe_to",
    #                                              :notification => "manufactured::event_occurred" },
    #                     :mining_stopped     => { :subscribe    => "manufactured::subscribe_to",
    #                                              :notification => "manufactured::event_occurred" }

    #  server_state :cargo_full,
    #    :check => lambda { |e| e.cargo_full?       },
    #    :on    => lambda { |e| e.offload_resources },
    #    :off   => lambda { |e|}

    #  # Start the omega client bot
    #  def start_bot
    #    handle_event(:mining_stopped) { |*args|
    #      offload_resources
    #    }

    #    if self.cargo_full?
    #      offload_resources
    #    else
    #      select_target
    #    end
    #  end

    #  #private

    #  # Internal helper, move to the closest station owned by user and
    #  # transfer resources to it
    #  def offload_resources
    #    st = closest(:station).first
    #    if st.location - self.location < self.transfer_distance
    #      transfer_all_to(st)
    #      self.select_target

    #    else
    #      Node.raise_event(:moving_to, self, st)
    #      move_to(:destination => st) { |*args|
    #        transfer_all_to(st)
    #        self.select_target
    #      }
    #    end
    #  end

    #  # Internal helper, select next resource, move to it, and commence mining
    #  def select_target
    #    rs = closest(:resource).first
    #    if rs.nil?
    #      Node.raise_event(:no_resources, self)
    #      return
    #    else
    #      Node.raise_event(:selected_resource, self, rs)
    #    end

    #    if rs.location - self.location < self.mining_distance
    #      rs = rs.resource_sources.find { |rsi| rsi.quantity > 0 }

    #      # server resource may by depleted at any point, 
    #      # need to catch errors, and try elsewhere
    #      begin
    #        mine(rs)
    #      rescue Exception => e
    #        select_target
    #      end

    #    else
    #      dst = self.mining_distance / 4
    #      nl  = rs.location + [dst,dst,dst]
    #      rs  = rs.resource_sources.find { |rsi| rsi.quantity > 0 }
    #      move_to(:location => nl) { |*args|
    #        begin
    #          mine(rs)
    #        rescue Exception => e
    #          select_target
    #        end
    #      }
    #    end
    #  end

    #end

  end
end
