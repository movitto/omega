# Serializable Procedure
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

# sourcify use has been removed from the main app for security reasons
# but is used in the test suite for convenience purposes
# https://github.com/ngty/sourcify

# XXX bug w/ sourcify 0.5.0 and double quotes, use > 0.6.0.rc2
# https://github.com/ngty/sourcify/issues/25

# XXX bug w/ sourcify 0.6.0 and method hash parameters, use > 0.6.0.rc4
# https://github.com/ngty/sourcify/issues/27

# XXX make sure to define sprocs on their own lines:
# https://github.com/ngty/sourcify#2-multiple-matching-procs-per-line-error

require 'sourcify'

require 'delegate'

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

    # TODO ensure block is a lambda/proc/other callable?
    super(@block)
  end

  # Implementation of Object::==
  def ==(other)
    @sblock == other.sblock rescue false
  end

  # Implementation of Object::inspect
  def inspect
    "#<SProc: #{@sblock.inspect}>"
  end

  # Return string representation of code block
  def to_s
    @sblock
  end

  # Convert SProc to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:sblock => @sblock}
    }.to_json(*a)
  end

  # Create new SProc from json representation and return it
  def self.json_create(o)
    sproc = new(o['data']['sblock'])
    return sproc
  end

end
