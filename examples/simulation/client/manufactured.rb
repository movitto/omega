# Manufactured client definitions to be loaded by bin/rjr-client
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# FIXME this module requires user_perms to be disabled as currently
# rjr-client doesn't have any means to log the user in if privileges
# are required to view/modify entities

require 'omega'

include RJR::MessageMixins

def dispatch_manufactured(dispatcher)
  dispatcher.handle "manufactured::event_occurred" do |*args|
  end

  0.upto(5) { |i|
    0.upto(3) { |j|
      eid = "entity_#{i}-#{j}"

      define_message "get_#{eid}" do
        { :method => "manufactured::get_entity",
          :params => ['with_id', eid],
          :result => lambda { |e| e.id == eid } }
      end
        
      case j % 3
      when 0 then
        define_message "subscribe_to_#{eid}_resource_depleted" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'resource_depleted'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end

        define_message "subscribe_to_#{eid}_resource_collected" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'resource_collected'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end

        define_message "subscribe_to_#{eid}_mining_stopped" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'mining_stopped'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end

        define_message "start_mining_#{eid}" do
          { :method => "manufactured::start_mining",
            :params => [eid, "#{eid}_target", "metal-#{eid}_target_resource"],
            :result => lambda { |sh| sh.id == eid } }
        end

        define_message "transfer_resource_#{eid}" do
          { :method => 'manufactured::transfer_resource',
            :params => [eid, "#{eid}-transport", "metal-#{eid}_resource", 10],
            :result => lambda { |shs| shs.first.id == eid &&
                                      shs.last.id == "#{eid}-transport" } }
        end

      when 1 then
        # XXX only supporting corvette movement atm
        define_message "move_#{eid}" do
          { :method => "manufactured::move_entity",
            :params => [eid, lambda { Motel::Location.random(:min => 100, :max => 10000) }],
            :result => lambda { |sh|
              [Motel::MovementStrategies::Linear,
               Motel::MovementStrategies::Rotate].include?(sh.location.movement_strategy.class)
            }
          }
        end

        define_message "subscribe_to_#{eid}_attacked_stop" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'attacked_stop'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end
      
        define_message "subscribe_to_#{eid}_defended_stop" do
          { :method => "manufactured::subscribe_to",
            :params => ["#{eid}-opponent", 'defended_stop'],
            :result => lambda { |sh| sh.id == "#{eid}-opponent" },
            :transports => [:tcp, :ws, :amqp] }
        end

        define_message "subscribe_to_#{eid}_attacked" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'attacked'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end

        define_message "subscribe_to_#{eid}_defended" do
          { :method => "manufactured::subscribe_to",
            :params => ["#{eid}-opponent", 'defended'],
            :result => lambda { |sh| sh.id == "#{eid}-opponent" },
            :transports => [:tcp, :ws, :amqp] }
        end
      

        define_message "subscribe_to_#{eid}_destroyed" do
          { :method => "manufactured::subscribe_to",
            :params => ["#{eid}-opponent", 'destroyed'],
            :result => lambda { |sh| sh.id == "#{eid}-opponent" },
            :transports => [:tcp, :ws, :amqp] }
        end

        define_message "attack_#{eid}" do
          { :method => "manufactured::attack_entity",
            :params => [eid, "#{eid}-opponent"],
            :result => lambda { |shs| shs.first.id == eid &&
                                      shs.last.id == "#{eid}-opponent" } }
        end

      else
        # subscribe_to construction callbacks
        define_message "subscribe_to_#{eid}_construction_complete" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'construction_complete'],
            :result => lambda { |st| st.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end
      
        define_message "subscribe_to_#{eid}_partial_construction" do
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'partial_construction'],
            :result => lambda { |st| st.id == eid },
            :transports => [:tcp, :ws, :amqp] }
        end
      
        # construct entity
        # FIXME when invoked via rjr-client session_id won't be set
        # and thus serverside user_id / current_user (as accessed in
        # construct_entity rjr defintion) will be nil / cause error
        #define_message "construct_#{eid}" =>
        #  { :method => "manufactured::construct_entity",
        #    :params => [eid, "Manufactured::Ship", 'type', 'destroyer'],
        #    :result => lambda { |shs| shs.first.id == eid &&
        #                              shs.last.class == Manufactured::Ship } }
        #end
      end
    }
  }

  # get all entities
  define_message :get_all_entities do
    { :method => 'manufactured::get_entities',
      :params => [] }
  end

  # create_entity
  #define_message :create_entity do
  #  { :method => 'manufactured::create_entity',
  #    :params => [''],
  #    :result => }
  #end
end

alias :dispatch_examples_simulation_client_manufactured :dispatch_manufactured 
