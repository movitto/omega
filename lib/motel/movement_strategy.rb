# The MovementStrategy entity
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'motel/common'
require 'motel/location'

module Motel

# A MovementStrategy is registered with a {Motel::Location}
# and used by the {Motel::Registry} to update the location's coordinates
# in accordance to the algorithm and parameters of the strategy.
#
# This is the base class that defines the movement strategy interface,
# subclasses should be defined to update the location in various manners.
# Each should implement the {#move} method to update the location passed
# to it along with the number of seconds since move was last invoked.
class MovementStrategy
   # The minimum number of seconds the runner should wait before invoking move
   attr_accessor :step_delay

   # MovementStrategy initializer
   #
   # @param [Hash] args hash of options to initialize movement strategy with
   # @option args [Float,Integer] :step_delay base step delay which runner will wait before moving entity
   def initialize(args = {})
      attr_from_args args, :step_delay => 1
   end

   # Validate movement strategy, default to false, must be subclassed
   def valid?
     false
   end

   # Return bool indicating if we should change movement strategy
   def change?
     false
   end

   # Moves the given location, specifying the number of seconds which have
   # elapsed since move was last called
   def move(location, elapsed_seconds)
   end

   # Convert movement strategy to human readable string and return it
   def to_s
     "movement_strategy-#{self.class.to_s}"
   end

   # Convert movement strategy to json representation and return it
   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay }
     }.to_json(*a)
   end

   # Create new movement strategy from json representation
   def self.json_create(o)
     new(o['data'])
   end

end

end # module Motel
