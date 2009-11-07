# alters the Locations table by adding a generic / polymorphic
# 'entities' association (entity_id & entity_type columns)
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'motel'

# ActiveRecord::Migration 004
class AlterLocationsAddGenericAssociation < ActiveRecord::Migration
  def self.up
     add_column :locations, :entity_id, :int
     add_column :locations, :entity_type, :string, :size => 20
  end

  def self.down
     remove_column :locations, :entity_id
     remove_column :locations, :entity_type
  end
end
