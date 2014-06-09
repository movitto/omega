# common & useful methods and other.
#
# Things that don't fit elsewhere
#
# Copyright (C) 2012-2013 Mo Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users

# Generate and return a random string of the specified length
#
# @param [Integer] length length of the string to generate
def self.random_string(length)
  (0...length).map{65.+(rand(25)).chr}.join
end

end

# http://stackoverflow.com/a/436724
class Class
  def subclasses
    ObjectSpace.each_object(Class).select { |klass| klass < self }
  end
end
