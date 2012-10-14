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
        Omega::Client::Tracker.em_schedule_async(10){
          Omega::Client::Tracker.select { |k,v|
            k =~ /#{Omega::Client::Station.entity_type}-.*/ 
          }.each { |k,st|
            st.get
            if !st.init &&
                st.can_construct?(:entity_type => st.entity_to_construct['class'], # TODO run in while loop
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
        @@construction_timer ||= self.class.schedule_construction_cycle
      end

      def init
        return false if @stay_in_system || @found_system

        # stay in system if there are no other stations
        if Omega::Client::Station.owned_by(self.entity.user_id).
                                  find { |st| st.system_name == self.system_name &&
                                              st.id != self.id }.nil?
          @found_system = true
          return false
        end

        @visited_systems ||= []
        @visited_systems << self.solar_system
        next_system = nil

        self.solar_system.jump_gates.each { |jg|
          next_system = Omega::Client::Tracker[Omega::Client::SolarSystem.entity_type + '-' + jg.endpoint]
          next_system = Omega::Client::SolarSystem.get(jg.endpoint) if next_system.nil?
          if @visited_systems.include?(next_system)
            next_system = nil
          else
            break
          end
        }
        
        # TODO this might not check all systems + we should also move
        # to systems w/ fewer stations that others
        if next_system.nil?
          @found_system = true
          return false
        end

        self.jump_to(next_system)
        return true
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
