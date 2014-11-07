# Omega Client CollectsResources Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module CollectsResources
      def self.included(base)
        base.entity_event \
          :resource_collected =>
            {:subscribe    => "manufactured::subscribe_to",
             :notification => "manufactured::event_occurred",
             :match => proc { |entity,*a|
               a[0] == 'resource_collected' &&
               a[1].id == entity.id },
             :update => proc { |entity, *a|
               rs = a[2] ; rs.quantity = a[3]
               entity.add_resource rs
             }},

          :mining_stopped     =>
            {:subscribe    => "manufactured::subscribe_to",
             :notification => "manufactured::event_occurred",
             :match => proc { |entity,*a|
               a[0] == 'mining_stopped' &&
               a[1].id == entity.id
             },
             :update => proc { |entity,*a|
               #entity.entity = a[1] # may contain resources already removed
               entity.stop_mining
             }}

        base.server_state :cargo_full,
          :check => lambda { |e| e.cargo_full?       },
          :on    => lambda { |e| e.offload_resources },
          :off   => lambda { |e| }
      end

      # Mine the specified resource
      #
      # All server side mining restrictions apply, this method does
      # not do any checks b4 invoking start_mining so if server raises
      # a related error, it will be reraised here
      #
      # @param [Cosmos::Resource] resource to start mining
      def mine(resource)
        RJR::Logger.info "Starting to mine #{resource.material_id} with #{id}"
        @entity = node.invoke 'manufactured::start_mining', id, resource.id
      end

      # Select next resource, move to it, and commence mining
      def select_mining_target
        ast = closest(:resource).first
        if ast.nil?
          raise_event(:no_resources)
          return
        else
          raise_event(:selected_resource, ast)
        end

        rs  = ast.resources.find { |rsi| rsi.quantity > 0 }

        if ast.location - location < mining_distance
          # server resource may by depleted at any point,
          # need to catch errors, and try elsewhere
          begin
            mine(rs)
          rescue Exception => e
            select_mining_target
          end

        else
          dst = mining_distance / 4
          nl  = ast.location + [dst,dst,dst]
          move_to(:location => nl) { |*args|
            begin
              mine(rs)
            rescue Exception => e
              select_mining_target
            end
          }
        end
      end
    end # module CollectsResources
  end # module Client
end # module Omega
