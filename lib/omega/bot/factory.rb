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
      attr_accessor :stay_in_system

      def on_event(event, &bl)
        if event == 'on_construction'
          @on_construction_callback = bl
          return
        end

        super(event, &bl)
      end

      # run construction cycle
      def schedule_construction_cycle
        # TODO variable cycle interval
        @proximity_timer =
          Omega::Client::Tracker.em_schedule_async(5){
            self.get

            if self.can_construct?(:entity_type => @construct_entity_class,
                                   :type => @construct_entity_args['type'])
              @construct_entity_args['id'] = "#{@construct_entity_args['idt']}#{Omega::Client::Tracker.next_id}"
              entity = self.construct @construct_entity_class, @construct_entity_args
              @on_construction_callback.call self, entity if @on_construction_callback
            end
            self.schedule_construction_cycle
          }
      end

      def start
        init
        schedule_construction_cycle
      end

      def init
        return if @initialized

        @initialized = true

        # jump to system w/ fewest stations owned by user
        # TODO cache stations & systems so we don't have to retrieve every time
        return if @stay_in_system
        owned_stations = Omega::Client::Station.owned_by(self.entity.user_id)
        all_systems    = Omega::Client::SolarSystem.get_all
        all_systems.sort! { |a,b| owned_stations.select { |st| st.solar_system.name == a.name }.size <=>
                                  owned_stations.select { |st| st.solar_system.name == b.name }.size }
        if all_systems.first.name != self.solar_system.name
          self.jump_to all_systems.first
        end
      end

      def construct_entity_type=(val)
        # idt -> id template, which unique id is appended onto on construction
        @construct_entity_type = val
        @construct_entity_class, @construct_entity_args = 
          case @construct_entity_type
            when 'factory' then
              ['Manufactured::Station', {'type' => :manufacturing,
                                        'idt'   => "#{self.user_id}-manufacturing-station"}]
            when 'miner' then
              ['Manufactured::Ship',    {'type' => :mining,
                                        'idt'   => "#{self.user_id}-mining-ship"}]
            when 'corvette' then
              ['Manufactured::Ship',    {'type' => :corvette,
                                        'idt'   => "#{self.user_id}-corvette-ship"}]
          end

      end
    end
  end
end
