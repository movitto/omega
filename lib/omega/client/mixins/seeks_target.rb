# Omega Client SeeksTarget Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Client
    module SeeksTarget
      def next_target
        avail_targets.first
      end

      def target_avail?
        !next_target.nil?
      end

      def seek_target
        target = next_target
        move_to(:location => target.location) {
          raise_event(:near_target, target)
        }
      end

      def seek_and_destroy
        handle(:near_target) { |target| attack(target) }
        seek_target
      end

      def seek_and_destroy_all
        handle(:attacked_stop){ |*args| seek_target }
        seek_and_destroy
      end

    end # module SeeksTarget
  end # module Client
end # module Omega
