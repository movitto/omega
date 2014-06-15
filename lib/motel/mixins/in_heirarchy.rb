# Motel InHeirarchy Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel

# Mixed into Location, provides methods related to location parent
# and children
module InHeirarchy
  # ID of location's parent
  attr_accessor :parent_id

  # [Motel::Location] parent location
  attr_accessor :parent

  # [Array<Motel::Location>] child locations
  attr_accessor :children

  # Return updatable heirarchy attributes
  def updatable_heirarchy_attrs
    [:parent, :parent_id]
  end

  # Set location's parent_id
  #
  # (nullifies parent if changing)
  # @param [Integer] parent_id new parent id to set
  def parent_id=(parent_id)
    @parent = nil if parent_id != @parent_id
    @parent_id = parent_id
  end

  # Set location's parent
  #
  # (also sets parent_id accordingly)
  # @param [Motel::Location] new_parent new parent to set on location
  def parent=(new_parent)
    @parent = new_parent
    @parent_id = @parent.nil? ? nil : @parent.id
  end

  # Initialize default heirarchy / heirarchy from arguments
  def heirarchy_from_args(args)
    attr_from_args args, :children  => [],
                         :parent    => nil,
                         :parent_id => nil
  end

  # Return the root location on this location's heirarchy tree
  #
  # @return [Motel::Location]
  def root
    return self if parent.nil?
    return parent.root
  end

  # Traverse all chilren recursively, calling specified block for each
  #
  # @param [Callable] bl block to call with each child location as a param (recursively)
  def each_child(&bl)
    children.each { |child|
      if bl.arity == 1
        bl.call child
      elsif bl.arity == 2
        bl.call self, child
      end
      child.each_child &bl
    }
  end

  # Add new child to location
  #
  # @param [Motel::Location] child location to add under this one
  def add_child(child)
    @children << child unless @children.include?(child)
  end

  # Remove child from location
  #
  # @param [Motel::Location,Integer] child child location to move or its string id
  def remove_child(child)
    @children.reject!{ |ch| ch == child || ch.id == child }
  end

  # Return heirarchy properties in json format
  def heirarchy_json
    {:parent_id => parent_id,
     :children  => children}
  end

  # Return parent_id in string format
  def parent_id_str
    parent_id.nil? ? "" : parent_id[0...8]
  end
end # module InHeirarchy
end # module Motel
