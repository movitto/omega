# loads and runs all tests for the motel project
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

CURRENT_DIR=File.dirname(__FILE__)
$: << File.expand_path(CURRENT_DIR + "/../lib")

require 'motel'

class TestMovementStrategy < Motel::MovementStrategy
   attr_accessor :times_moved

   def initialize
     @times_moved = 0
     @step_delay = 1
   end

   def move(loc, elapsed_time)
     @times_moved += 1
   end
end
