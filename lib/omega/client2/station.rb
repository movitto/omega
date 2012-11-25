# Omega client station tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    # Omega client Manufactured::Station tracker
    class Station
      include RemotelyTrackable
      include HasLocation
      include InSystem

      entity_type  Manufactured::Station

      get_method   "manufactured::get_entity"
    end

    # Omega client manufacturing station tracker
    class Factory < Station
      include InteractsWithEnvironment
      #entity_validation { |e| e.type == 'manufacturing' }

      server_event       :received      => {},
                         :constructed   => {}

      # Get/set the type of entity to construct using this station
      def entity_type(val=nil)
        return @entity_type if val.nil?
        @entity_type = construction_options(entity_type)
      end

      # Start the omega client bot
      def start_bot
        self.pick_system
        self.start_construction
      end

      private

      # Internal helper, begin construction cycle
      def start_construction
        if self.can_construct?(@entity_type)
          entity = Hash.new(@entity_type)
          entity['id'] = entity['idt'] + Node.next_id
          construct(entity['entity_type'], entity)
        end
      end

      # Internal helper, pick system with no stations or the fewest stations
      # and jump to it
      def pick_system
        system = System.with_fewest("Manufactured::Station")
        # TODO first determine if there are systems w/ no stations
        self.jump_to(system)
      end

      # Internal helper, generate construction options from high level entity type
      def construction_options(entity_type)
        case entity_type
          when 'factory' then
            {'entity_type' => 'Manufactured::Station',
             'class' => 'Manufactured::Station',
             'type'  => :manufacturing,
             'idt'   => "#{Node.user.id}-manufacturing-station"}
          when 'miner' then
            {'entity_type' => 'Manufactured::Ship',
             'class' => 'Manufactured::Ship',
             'type'  => :mining,
             'idt'   => "#{Node.user.id}-mining-ship"}
          when 'corvette' then
            {'entity_type' => 'Manufactured::Ship',
             'class' => 'Manufactured::Ship',
             'type'  => :corvette,
             'idt'   => "#{Node.user.id}-corvette-ship"}
        end
      end
    end
  end
end
