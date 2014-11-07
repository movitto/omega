# Omega Client OffloadsResources Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module OffloadsResources
      # Move to the closest station owned by user and transfer resources to it
      def offload_resources
        st = closest(:station).first

        if st.nil?
          raise_event(:no_stations)
          return

        elsif st.location - location < transfer_distance
          begin
            transfer_all_to(st)

            # allow two errors before giving up
            @transfer_errs = 0
          rescue Exception => e
            @transfer_errs ||= 0
            @transfer_errs  += 1
            if @transfer_errs > 2
              raise_event(:transfer_err, st)
              return
            end

            # refresh stations and try again
            Omega::Client::Station.refresh
            offload_resources
            return
          end

          # FIXME genericize this / raise event
          select_mining_target

        else
          raise_event(:moving_to, st)
          move_to(:destination => st) { |*args|
            offload_resources
          }
        end
      end
    end # module OffloadsResources
  end # module Client
end # module Omega
