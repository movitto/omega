#!/usr/bin/ruby
# omega bot factory station tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Bot
    class Factory < Omega::Client::Station
      # stay in current system unless jump is explicitly invoked by user
      attr_writer :stay_in_system

      # XXX don't like exposing these next attributes, but needed
      # for construction cycle below

      # callback invoked when new entities are constructed
      attr_reader :on_construction_callback

      # entity which this station will construct
      attr_reader :entity_to_construct

      def on_event(event, &bl)
        if event == 'on_construction'
          @on_construction_callback = bl
          return
        end

        super(event, &bl)
      end

      # run construction cycle
      def self.schedule_construction_cycle
        # TODO variable cycle interval
        Omega::Client::Tracker.em_schedule_async(30){
          Omega::Client::Tracker.select { |k,v|
            k =~ /#{Omega::Client::Station.entity_type}-.*/ 
          }.each { |k,st|
            st.get

            if st.can_construct?(:entity_type => st.entity_to_construct['class'],
                                 :type        => st.entity_to_construct['type'])

              st.entity_to_construct['id'] =
                "#{st.entity_to_construct['idt']}#{Omega::Client::Tracker.next_id}"

              entity = st.construct st.entity_to_construct['class'], st.entity_to_construct
              st.on_construction_callback.call st, entity if st.on_construction_callback
            end
          }
          self.schedule_construction_cycle
        }
      end

      def start
        init
        @@construction_timer ||= self.class.schedule_construction_cycle
      end

      def init
        return if @initialized
        @initialized = true

        # jump to system w/ fewest stations owned by user
        # TODO only systems w/ resources
        return if @stay_in_system
        owned_stations = Omega::Client::Station.owned_by(self.entity.user_id)
        all_systems    = Omega::Client::SolarSystem.get_all
        system_stations = Hash[*all_systems.collect { |sys| [sys.name, 0] }.flatten]
        owned_stations.each { |st| system_stations[st.system_name] += 1 }
        target_system = all_systems.sort { |a,b| system_stations[a.name] <=> system_stations[b.name] }.first

        self.jump_to(target_system) if !target_system.nil? && target_system.name != self.system_name
      end

      def construct_entity_type=(val)
        # idt -> id template, which unique id is appended onto on construction
        @entity_to_construct = 
          case val
            when 'factory' then
              {'class' => 'Manufactured::Station',
               'type'  => :manufacturing,
               'idt'   => "#{self.user_id}-manufacturing-station"}
            when 'miner' then
              {'class' => 'Manufactured::Ship',
               'type'  => :mining,
               'idt'   => "#{self.user_id}-mining-ship"}
            when 'corvette' then
              {'class' => 'Manufactured::Ship',
               'type'  => :corvette,
               'idt'   => "#{self.user_id}-corvette-ship"}
          end

      end
    end
  end
end
