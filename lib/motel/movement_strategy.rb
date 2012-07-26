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
   attr_accessor :step_delay
   
   def initialize(args = {})
      @step_delay = 1 # TODO make configurable

      args.each { |k,v|
        inst_attr = ('@' + k.to_s).to_sym
        instance_variable_set(inst_attr, args[k])
      }
   end

   # default movement strategy is to do nothing
   def move(location, elapsed_seconds)
   end

   def to_s
     "movement_strategy-#{self.class.to_s}"
   end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       => { :step_delay => step_delay }
     }.to_json(*a)
   end

   def self.json_create(o)
     new(o['data'])
   end

end

end # module Motel
