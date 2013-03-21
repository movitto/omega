# A statistic
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'json'

module Stats

# Describes a bit of high level information about the universe
class Stat
  # id of the statistic
  attr_accessor :id

  # method used to generator the statistic
  attr_accessor :generator

  # Invoke generator w/ the specified params to collect stat and return value.
  def generate(*args)
    # TODO support for caching results for a period (would require concurrent access protection)
    value = @generator.call(*args)
    StatResult.new :stat_id => self.id, :args => args, :value => value
  end

  # Statistic initializer
  # @param [Hash] args hash of options to initialize stat with
  # @option args [String] :id,'id' id to assign to the stat
  # @option args [Callable] :generator,'generator' generator to assign to the stat
  def initialize(args = {})
    @id        = args[:id]        || args['id']        || nil
    @generator = args[:generator] || args['generator'] || nil
  end

end

# Encapsultates a statistic result
class StatResult
  # id of the statistic this result belongs to
  attr_accessor :stat_id

  # array of args used to generated the stat
  attr_accessor :args

  # actual value of the result
  attr_accessor :value

  # StatResult initializer
  # @param [Hash] args hash of options to initialize result with
  # @option args [String] :stat_id,'stat_id' stat_id to assign to the result
  # @option args [Object] :value,'value' value to assign to the result
  def initialize(args = {})
    @stat_id   = args[:stat_id]   || args['stat_id']   || nil
    @args      = args[:args]      || args['args']      || []
    @value     = args[:value]     || args['value']     || nil
  end

  # Convert stat result to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       =>
        {:stat_id => stat_id, :args => args, :value => value}
    }.to_json(*a)
  end

  # Create new stat resultfrom json representation
  def self.json_create(o)
    res = new(o['data'])
    return res
  end

end

end
