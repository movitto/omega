# creates the neccessary fields for the Linear MovementStrategy
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel'

# ActiveRecord::Migration 002
class CreateLinearMovementStrategy < ActiveRecord::Migration
  def self.up
     add_column :movement_strategies, :speed,              :float
     add_column :movement_strategies, :direction_vector_x, :float
     add_column :movement_strategies, :direction_vector_y, :float
     add_column :movement_strategies, :direction_vector_z, :float
  end

  def self.down
     remove_column :movement_strategies, :speed
     remove_column :movement_strategies, :direction_vector_x
     remove_column :movement_strategies, :direction_vector_y
     remove_column :movement_strategies, :direction_vector_z
  end
end
