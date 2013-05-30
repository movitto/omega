# Initialize the motel subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

def dispatch_init(dispatcher)
  Motel::Registry.instance.start
end
