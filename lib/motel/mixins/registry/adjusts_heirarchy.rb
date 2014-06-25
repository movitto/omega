# Motel Adjusts Heirarchy Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
module AdjustsHeirarchy
  # Setup parent when entity is added or updated.
  def adjust_heirarchry(nloc, oloc=nil)
    nparent = @entities.find { |l|
                l.id == nloc.parent_id
              } unless nloc.parent_id.nil?

    oparent = @entities.find { |l|
                l.id == oloc.parent_id
              } unless oloc.nil? || oloc.parent_id.nil?

    if oparent != nparent
      oparent.remove_child(nloc) unless oparent.nil?
      nparent.add_child(nloc)    unless nparent.nil?
      nloc.parent = nparent
    end
  end
end # module AdjustsHeirarchy
end # module Motel
