# Missions Subsystem Utility Methods
#
# Assortment of helper methods and methods that don't fit elsewhere
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# XXX we use sourcify to move blocks of code pertaining to Mission
# system operations around, be careful who has write access to this!
# https://github.com/ngty/sourcify
require 'sourcify'

# Wrapper around a block of code to autoserialize
# its source to a string and support conversion to json
class SProc  < DelegateClass(Proc)
  # String representation of encapsulated code block
  attr_reader :sblock

  # Handle to encapsulated code block
  attr_reader :block

  # SProc initializer, specifying the block of code or string representation.
  #
  # Note one of the two must be specified else a runtime error will be thrown.
  # @param [String] sblock string representation of the encapsulated block
  # @param [Callable] block encapsulated block of code
  def initialize(sblock = nil, &block)
    unless sblock.nil?
      @sblock = sblock
      @block  = eval(sblock)
    end

    unless block.nil?
      @sblock = block.to_source
      @block  = block
    end

    if sblock.nil? && block.nil?
      raise RuntimeError, "must specify code block or string representation"
    end
  end

  # Implementation of Object::==
  def ==(other)
    @sblock == other.sblock rescue false
  end

  # Implementation of Object::inspect
  def inspect
    "#<SProc: #{@sblock.inspect}>"
  end
  alias :to_s :inspect

  # Convert SProc to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:sblock => @sblock}
    }.to_json(*a)
  end

  # Create new SProc from json representation and return it
  def self.json_create(o)
    sproc = new(o['data'][:sblock])
    return sproc
  end

end
