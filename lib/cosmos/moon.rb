# Cosmos Moon definition
#
# Copyright (C) 2010-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Cosmos
class Moon
  attr_accessor :name
  attr_accessor :location

  attr_reader :planet

  def initialize(args = {})
    @name = args['name'] || args[:name]
    @location = args['location'] || args[:location]
    @planet   = args['planet']   || args[:planet]

    if @location.nil?
      @location = Motel::Location.new
      @location.x = @location.y = @location.z = 0
    end
  end

  def valid?
    !@name.nil? && @name.is_a?(String) && @name != "" &&
    !@location.nil? && @location.is_a?(Motel::Location) && @location.movement_strategy.class == Motel::MovementStrategies::Stopped &&
    (@planet.nil? || @planet.is_a?(Cosmos::Planet))
  end

  # does not accept any resources
  # TODO change
  def accepts_resource?(res)
    false
  end

  def parent
    @planet
  end

  def parent=(planet)
    @planet = planet
  end

  def self.parent_type
    :planet
  end

  def self.remotely_trackable?
    false
  end

  def has_children?
    false
  end

   def to_json(*a)
     {
       'json_class' => self.class.name,
       'data'       =>
         {:name => name, :location => @location}
     }.to_json(*a)
   end

   def to_s
     "moon-#{name}"
   end

   def self.json_create(o)
     moon = new(o['data'])
     return moon
   end

end
end
