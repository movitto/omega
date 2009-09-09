# creates the locations and movement_strategies tables
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel'

# ActiveRecord::Migration 001
class CreateLocationsAndMovementStrategies < ActiveRecord::Migration
  def self.up

     create_table :movement_strategies do |t|
        t.string  :type,        :null => false, :size => 50
        t.float   :step_delay,  :null => false
     end

     create_table :locations do |t|
        t.float :x, :default => nil
        t.float :y, :default => nil
        t.float :z, :default => nil
        t.integer :movement_strategy_id, :null => false

        t.integer :parent_id, :default => nil
     end

     execute "alter table locations add constraint fk_location_parent
              foreign key(parent_id) references locations(id)"

     execute "alter table locations add constraint fk_location_movement_strategy
              foreign key(movement_strategy_id) references movement_strategies(id)"

     execute "alter table locations add constraint root_or_child 
              check (parent_id IS NULL AND x IS NULL AND y IS NULL AND z IS NULL OR
                     parent_id IS NOT NULL AND x IS NOT NULL AND y IS NOT NULL AND z IS NOT NULL)"


     # create the first / default movement strategy 'stopped'
     Motel::Models::Stopped.new(:step_delay => 5).save!
  end

  def self.down
     drop_table :locations
     drop_table :movement_strategies
  end
end
