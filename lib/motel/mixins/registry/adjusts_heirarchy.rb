# Motel Adjusts Heirarchy Mixin
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Motel
module AdjustsHeirarchy
  def adjust_heirarchry(nloc, oloc=nil)
    @lock.synchronize{
      rloc = @entities.find { |e| e.id == nloc.id }

      nparent =
        @entities.find { |l|
          l.id == nloc.parent_id
        } unless nloc.parent_id.nil?

      oparent = oloc.nil? || oloc.parent_id.nil? ?
                                             nil :
                  @entities.find { |l| l.id == oloc.parent_id }

      if oparent != nparent
        oparent.remove_child(rloc) unless oparent.nil?

        # TODO if nparent.nil? throw error?
        nparent.add_child(rloc) unless nparent.nil?
        rloc.parent = nparent
      end

    }
  end
end # module AdjustsHeirarchy
end # module Motel
