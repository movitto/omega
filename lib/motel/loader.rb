# The Loader class definition
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel/runner'

module Motel

# A Loader loads instances of Location from the db
# according to any specified conditions, instantiates
# a new Runner for each of those locations and returns them
class Loader
  
 public

  # Default class constructor
  def initialize
  end

  # Static member to load all locations that match a specified 
  # condition (ala activerecord) and create and return a Runner 
  # instance  (or use the optional one passed in), using it to run 
  # the locations. 
  def self.Load(conditions = 'parent_id IS NULL', runner = Runner.new)
     locations = Location.find(:all, :conditions => conditions)
     return nil if locations.size == 0

     locations.each { |location|
       run_location(runner, location)
     }

     return runner
  end

 private

  # Static internal helper method that adds a location and 
  # all its children to the specified runner.
  def self.run_location(runner, location)
    runner.run location
    location.children.each { |child|
       run_location runner, child
    }
  end

end

end
