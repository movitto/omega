# Motel DSL
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# establish client connection w/ specified args and invoke block w/ 
# newly created client, returning it after block terminates
def connect(args = {}, &block)
   client = Motel::Client.new(args)
   block.call client unless block.nil?
   return client
end
