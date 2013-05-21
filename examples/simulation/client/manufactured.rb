# Manufactured client definitions to be loaded by bin/rjr-client
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

require 'rjr/util'
require 'manufactured'
include RJR::Definitions

rjr_method \
  "manufactured::event_occurred" =>
    lambda { |*args|
    }

0.upto(25) { |i|
  0.upto(6) { |j|
    eid = "entity_#{i}-#{j}"

    rjr_message \
      "get_#{eid}" =>
        { :method => "manufactured::get_entity",
          :params => ['with_id', eid],
          :result => lambda { |e| e.id == eid } }
        
    case j % 3
    when 0 then
      # subscribe_to mining callbacks
      rjr_message \
        "subscribe_to_#{eid}_resource_depleted" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'resource_depleted'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] },

        "subscribe_to_#{eid}_resource_collected" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'resource_collected'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] },

        "subscribe_to_#{eid}_mining_stopped" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'mining_stopped'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] },

      # start_mining
        "start_mining_#{eid}" =>
          { :method => "manufactured::start_mining",
            :params => [eid, "#{eid}_target", "metal-#{eid}_target_resource"],
            :result => lambda { |sh| sh.id == eid } },

      # transfer resource
        "transfer_resource_#{eid}" =>
          { :method => 'manufactured::transfer_resource',
            :params => [eid, "#{eid}-transport", "metal-#{eid}_resource", 10],
            :result => lambda { |shs| shs.first.id == eid &&
                                      shs.last.id == "#{eid}-transport" } }

    when 1 then
      # move_entity
      # XXX only supporting corvette movement atm
      rjr_message \
        "move_#{eid}" =>
          { :method => "manufactured::move_entity",
            :params => [eid, lambda { Motel::Location.random(:min => 100, :max => 10000) }],
            :result => lambda { |sh|
              [Motel::MovementStrategies::Linear,
               Motel::MovementStrategies::Rotate].include?(sh.location.movement_strategy.class)
             }
           }

      # subscribe_to attack callbacks
      rjr_message \
        "subscribe_to_#{eid}_attacked_stop" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'attacked_stop'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] },
      

        "subscribe_to_#{eid}_defended_stop" =>
          { :method => "manufactured::subscribe_to",
            :params => ["#{eid}-opponent", 'defended_stop'],
            :result => lambda { |sh| sh.id == "#{eid}-opponent" },
            :transports => [:tcp, :ws, :amqp] },
      

        "subscribe_to_#{eid}_attacked" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'attacked'],
            :result => lambda { |sh| sh.id == eid },
            :transports => [:tcp, :ws, :amqp] },

        "subscribe_to_#{eid}_defended" =>
          { :method => "manufactured::subscribe_to",
            :params => ["#{eid}-opponent", 'defended'],
            :result => lambda { |sh| sh.id == "#{eid}-opponent" },
            :transports => [:tcp, :ws, :amqp] },
      

        "subscribe_to_#{eid}_destroyed" =>
          { :method => "manufactured::subscribe_to",
            :params => ["#{eid}-opponent", 'destroyed'],
            :result => lambda { |sh| sh.id == "#{eid}-opponent" },
            :transports => [:tcp, :ws, :amqp] },

      # attack_entity call
      "attack_#{eid}" =>
        { :method => "manufactured::attack_entity",
          :params => [eid, "#{eid}-opponent"],
          :result => lambda { |shs| shs.first.id == eid &&
                                    shs.last.id == "#{eid}-opponent" } }

    else
      # subscribe_to construction callbacks
      rjr_message \
        "subscribe_to_#{eid}_construction_complete" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'construction_complete'],
            :result => lambda { |st| st.id == eid },
            :transports => [:tcp, :ws, :amqp] },
      
        "subscribe_to_#{eid}_partial_construction" =>
          { :method => "manufactured::subscribe_to",
            :params => [eid, 'partial_construction'],
            :result => lambda { |st| st.id == eid },
            :transports => [:tcp, :ws, :amqp] }
      

      # construct entity
      # FIXME when invoked via rjr-client session_id won't be set
      # and thus serverside user_id / current_user (as accessed in
      # construct_entity rjr defintion) will be nil / cause error
      #"construct_#{eid}" =>
      #  { :method => "manufactured::construct_entity",
      #    :params => [eid, "Manufactured::Ship", 'type', 'destroyer'],
      #    :result => lambda { |shs| shs.first.id == eid &&
      #                              shs.last.class == Manufactured::Ship } }

    end
  }
}

# get all entities
rjr_message \
  :get_all_entities =>
    { :method => 'manufactured::get_entities',
      :params => [] }

# create_entity
#rjr_message \
#  :create_entity =>
#    { :method => 'manufactured::create_entity',
#      :params => [''],
#      :result => }
