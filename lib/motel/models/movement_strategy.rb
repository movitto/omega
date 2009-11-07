# The MovementStrategy model definition
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/common'
require 'motel/models/location'

module Motel
module Models

# MovementStrategy subclasses define the rules and params which 
# a location changes its position. 
class MovementStrategy < ActiveRecord::Base
   # strategy is associated with location to move it
   has_many :locations, :dependent => :destroy

   # callbacks invoked when this object is moved
   attr_accessor :movement_callbacks

   # every movement strategy needs a type
   validates_presence_of :type

   # as more types are supported, add them here
   validates_inclusion_of :type, 
     :in => %w( Stopped Linear Elliptical )

   # step delay is recommended number of seconds 
   # a runner should sleep for between move invocations
   validates_presence_of :step_delay

   # default step_delay if not set
   before_validation :default_step_delay
   def default_step_delay
      self.step_delay = 5 if step_delay.nil?
   end

   # use after_initialize instead of initialize
   # http://blog.dalethatcher.com/2008/03/rails-dont-override-initialize-on.html
   def after_initialize
     @movement_callbacks = []
   end

   # default movement strategy is to do nothing
   def move(location, elapsed_seconds)
   end

   # retreive the 'stopped' movement strategy
   def self.stopped
     ms = MovementStrategy.find(:first, :conditions => "type = 'Stopped'")
     ms.nil? ? Stopped.new(:step_delay => 5) : ms
   end

   # return subclass corresponding to specified strategy type
   def self.factory(strategy_type)
     return MovementStrategy if strategy_type.nil?

     if strategy_type.downcase == "stopped" || strategy_type == "Motel::Models::Stopped"
       return Stopped
     elsif strategy_type.downcase == "linear" || strategy_type == "Motel::Models::Linear"
       return Linear
     elsif strategy_type.downcase == "elliptical" || strategy_type == "Motel::Models::Elliptical"
       return Elliptical
     end
     
     return MovementStrategy
   end
   
   # convert movement strategy to a hash
   def to_h
     {}
   end

   # convert movement strategy to a string
   def to_s
     "id:#{id}; type:#{self.class}" # XXX should be self.type but ruby will complain, this works for now
   end

end

end # module Models
end # module Motel
