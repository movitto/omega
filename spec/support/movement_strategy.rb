# Omega Spec Movement Strategy
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module OmegaTest
  class MovementStrategy < Motel::MovementStrategy
     attr_accessor :times_moved

     def initialize(args = {})
       @times_moved = 0
       @step_delay = 1
     end

     def move(loc, elapsed_time)
       @times_moved += 1
     end
  end
end
