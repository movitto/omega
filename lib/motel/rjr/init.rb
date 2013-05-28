# Initialize the motel subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

def dispatch_init(dispatcher)
  Motel::Registry.instance.start
  Motel::Registry.instance.validation =
    proc { |r,e| !r.collect { |l| l.id }.include?(e.id) }
end
