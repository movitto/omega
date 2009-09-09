# creates the neccessary fields for the Elliptical MovementStrategy
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel'

# ActiveRecord::Migration 003
class CreateEllipticalMovementStrategy < ActiveRecord::Migration
  def self.up
     # we already have speed from linear
     #add_column :movement_strategies, :speed,              :float

     # relative_to field indicates what type of parent
     # this movement stategy is relative to, for Ellilptical
     # strategies, this can be 'center' indicating the parent
     # is the center of the ellipse or 'foci' indicating the
     # parent is on of the ellipse foci's
     add_column :movement_strategies, :relative_to, :string, :size => 50

     # eccentricity of the ellipse
     add_column :movement_strategies, :eccentricity, :float

     # semi_latus_rectum of the ellipse
     add_column :movement_strategies, :semi_latus_rectum, :float

     # unit direction vector of the major axis
     add_column :movement_strategies, :direction_major_x, :float
     add_column :movement_strategies, :direction_major_y, :float
     add_column :movement_strategies, :direction_major_z, :float

     # unit direction vector of the minor axis
     add_column :movement_strategies, :direction_minor_x, :float
     add_column :movement_strategies, :direction_minor_y, :float
     add_column :movement_strategies, :direction_minor_z, :float
  end

  def self.down
     # remove in linear strategy
     #remove_column :movement_strategies, :speed

     remove_column :movement_strategies, :relative_to
     remove_column :movement_strategies, :eccentricity
     remove_column :movement_strategies, :semi_latus_rectum
     remove_column :movement_strategies, :direction_major_x
     remove_column :movement_strategies, :direction_major_y
     remove_column :movement_strategies, :direction_major_z
     remove_column :movement_strategies, :direction_minor_x
     remove_column :movement_strategies, :direction_minor_y
     remove_column :movement_strategies, :direction_minor_z
  end
end
