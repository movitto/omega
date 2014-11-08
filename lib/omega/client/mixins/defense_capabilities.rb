# Omega Client DefenseCapabilities Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module DefenseCapabilities
      def self.included(base)
        base.entity_event \
          :defended =>
            { :subscribe    => "manufactured::subscribe_to",
              :notification => "manufactured::event_occurred",
              :match => proc { |entity, *a|
                a[0] == 'defended' && a[1].id == entity.id },
              :update => proc { |entity, *a|
                entity.hp,entity.shield_level =
                  a[1].hp, a[1].shield_level
              }},

          :defended_stop =>
            { :subscribe    => "manufactured::subscribe_to",
              :notification => "manufactured::event_occurred",
              :match => proc { |entity, *a|
                a[0] == 'defended_stop' && a[1].id == entity.id },
              :update => proc { |entity, *a|
                entity.hp,entity.shield_level =
                  a[1].hp, a[1].shield_level
              }},

          :destroyed_by =>
            { :subscribe    => "manufactured::subscribe_to",
              :notification => "manufactured::event_occurred",
              :match => proc { |entity, *a|
                a[0] == 'destroyed_by' && a[1].id == entity.id },
              :update => proc { |entity, *a|
                entity.hp,entity.shield_level =
                  a[1].hp, a[1].shield_level
              }}

        # automatically cleanup entity when destroyed
        base.server_state :destroyed,
          :check => lambda { |e| !e.alive? },
          :off   => lambda { |e| },
          :on    =>
            lambda { |e|
              # not handling for now to allow processing of any
              # final messages received, may want to remove eventually
              # TODO remove rjr notifications
              #e.clear_handlers
            }
      end
    end # module DefenseCapabilities
  end # module Client
end # module Omega
