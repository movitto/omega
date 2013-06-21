# Omega client station tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    # Omega client Manufactured::Station tracker
    class Station
      include RemotelyTrackable
      include InSystem

      entity_type  Manufactured::Station

      get_method   "manufactured::get_entity"

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
        constructed = node.invoke 'manufactured::construct_entity',
                          self.entity.id, entity_type, *(args.to_a.flatten)
        self.raise_event(:constructed, self.entity, constructed)
        constructed
      end
    end

    # Omega client manufacturing station tracker
    #class Factory < Station
    #  include InteractsWithEnvironment
    #  #entity_validation { |e| e.type == 'manufacturing' }

    #  server_event       :construction_complete => {:subscribe    => "manufactured::subscribe_to",
    #                                                :notification => "manufactured::event_occurred"},
    #                     :partial_construction  => {:subscribe    => "manufactured::subscribe_to",
    #                                                :notification => "manufactured::event_occurred"},
    #                     :received      => {},
    #                     :constructed   => {}

    #  # Helper method to generate incremental id's
    #  def self.next_id
    #    @next_id ||= 42
    #    @next_id += 1
    #  end

    #  # Get/set the type of entity to construct using this station
    #  def entity_type(val=nil)
    #    return @entity_type if val.nil?
    #    @entity_type = construction_options(val)
    #  end

    #  # Start the omega client bot
    #  def start_bot
    #    self.start_construction
    #    self.handle_event(:received) { |*args|
    #      self.start_construction
    #    }
    #  end

    #  #private

    #  # Internal helper, begin construction cycle
    #  def start_construction
    #    if self.can_construct?(@entity_type)
    #      entity = Hash[@entity_type]
    #      entity[:id] = (entity[:idt] + self.class.next_id.to_s)
    #      construct(entity[:entity_type], entity)
    #    end
    #  end

    #  # Internal helper, pick system with no stations or the fewest stations
    #  # and jump to it
    #  def pick_system
    #    system = Omega::Client::SolarSystem.get(self.system_name). # TODO optimize
    #               closest_neighbor_with_no("Manufactured::Station")
    #    system = Omega::Client::SolarSystem.with_fewest "Manufactured::Station" if system.nil?
    #    # TODO first determine if there are systems w/ no stations
    #    self.jump_to(system) if system.name != self.solar_system.name
    #  end

    #  private

    #  # Internal helper, generate construction options from high level entity type
    #  def construction_options(entity_type)
    #    case entity_type
    #      when 'factory' then
    #        {:entity_type => 'Manufactured::Station',
    #         :class => 'Manufactured::Station',
    #         :type  => :manufacturing,
    #         :idt   => "#{Node.user.id}-manufacturing-station"}
    #      when 'miner' then
    #        {:entity_type => 'Manufactured::Ship',
    #         :class => 'Manufactured::Ship',
    #         :type  => :mining,
    #         :idt   => "#{Node.user.id}-mining-ship"}
    #      when 'corvette' then
    #        {:entity_type => 'Manufactured::Ship',
    #         :class => 'Manufactured::Ship',
    #         :type  => :corvette,
    #         :idt   => "#{Node.user.id}-corvette-ship"}
    #    end
    #  end
    #end
  end
end
