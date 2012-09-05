# common & useful methods and other.
#
# Things that don't fit elsewhere
#
# Copyright (C) 2012 Mo Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# include logger dependencies
require 'logger'

module Users

# Generate and return a random string of the specified length
#
# @param [Integer] length length of the string to generate
def self.random_string(length)
  (0...length).map{65.+(rand(25)).chr}.join
end

end
