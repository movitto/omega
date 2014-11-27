#!/usr/bin/ruby
# Most basic universe
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/client/boilerplate'

login 'admin', 'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925'
  #system 'Aphrodite', 'V866'
end

#athena    = system('Athena')
#aphrodite = system('Aphrodite')
#jump_gate athena,    aphrodite
