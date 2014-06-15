# Motel BaseAttrs Mixin.
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel

# Mixed into Location, provides base attributes
module BaseAttrs
  # ID of location
  attr_accessor :id

  # Boolean flag indicating if permission checks
  # should restrict access to this location
  attr_accessor :restrict_view

  # Boolean flag indicating if permission checks
  # should restrict modification of this location
  attr_accessor :restrict_modify

  # Initialize default base attributes / base attributes from arguments
  def base_attrs_from_args(args)
    # default to the stopped movement strategy
    attr_from_args args,
      :id                => nil,
      :restrict_view     => true,
      :restrict_modify   => true
  end

  # Return base attributes
  def base_attrs
    [:id, :restrict_view, :restrict_modify]
  end

  # Return updatable base attributes
  def updatable_base_attrs
    [:restrict_view, :restrict_modify]
  end

  # Return bool indicating if id is valid
  def id_valid?
    !@id.nil?
  end

  # Return base attributes in json format
  def base_json
    {:id              => id,
     :restrict_view   => restrict_view,
     :restrict_modify => restrict_modify}
  end
end # module BaseAttrs
end # module Motel
