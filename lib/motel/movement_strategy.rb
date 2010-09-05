# The MovementStrategy entity
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/location'

module Motel

# MovementStrategy subclasses define the rules and params which 
# a location changes its position. 
class MovementStrategy
   attr_accessor :id, :type

   attr_accessor :step_delay
   
   def initialize(args = {})
      @step_delay = 1

      @step_delay = args[:step_delay] if args.has_key?(:step_delay) && !args[:step_delay].nil?
   end

   # default movement strategy is to do nothing
   def move(location, elapsed_seconds)
   end

end

end # module Motel
