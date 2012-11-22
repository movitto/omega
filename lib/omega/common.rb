# Utility Methods
#
# Copyright (C) 2011-2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the Apache License, Version 2.0

class Array
  def uniq_by(&blk)
    transforms = {}
    select do |el|
      t = blk[el]
      should_keep = !transforms[t]
      transforms[t] = true
      should_keep
    end
  end
end
