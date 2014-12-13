# Omega Spec Core Extensions
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

class Class
  # allows us to invoke block between allocation and initialization
  def test_new(*params, &block)
    o = allocate
    yield(o) if block
    o.__send__(:initialize, *params)
    return o
  end
end
