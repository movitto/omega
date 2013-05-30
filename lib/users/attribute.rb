# Users module attribute definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'users/common'

module Users

# Attributes belong to users and reference a specific class
# of capabilities which the user may level up. Attribute types
# have requirements which the user must satisfy to unlock additional
# levels and attributes
class Attribute

  # Handle to attribute type instance specifying requirements and metadata
  attr_accessor :type

  # Level which this attribute is currently at
  attr_accessor :level

  # Progression to the next level
  attr_accessor :progression

  # Handle to user owning this attribute
  attr_accessor :user

  # Return the attribute 'total' or the level + progression
  def total
    @level + @progression
  end

  # Attribute initializer
  # @param [Hash] args hash of options to initialize attribute instance with
  # @option args [AttributeClass] :type,'type' type to assign to the attribute
  # @option args [String] :type_id,'type_id' id of type to assign to attribture
  # @option args [Integer] :level,'level' level to assign to attribute
  # @option args [Float] :progression,'progression' progression to assign to attribute
  def initialize(args = {})
    attr_from_args args, :type => nil, :level => 0, :progression => 0

    [:type_id, 'type_id'].each { |type_id|
      @type =
        AttributeClass.subclasses.find { |ac|
          ac.id == args[type_id].intern
      } if args[type_id]
    }
  end

  # Update progression of attribute.
  #
  # Ensures validity of attribute, also
  # invokes attribute_callbacks (and/or in Attribute)
  def update!(change)
    return if change < 0 && @level == 0 && @progression == 0
    old_l = @level ; old_p = @progression ; old_t = self.total
    # TODO if change type multiplier is set, scale change down by multipler&level
    @progression += change
    until (0...1.0).include?(@progression)
      if @progression >= 1.00
        @level += 1
        @progression -= 1
      elsif @progression < 0
        @level -= 1
        @progression += 1
      end
    end

    if @level < 0
      @level = 0
      @progression = 0
    end

    # invoke callbacks
    unless @type.nil?
      if @level > old_l
        # level_up, progression
        @type.invoke_callbacks(:level_up, self)
        @type.invoke_callbacks(:progression, self)

      elsif @level < old_l
        # level_down, regression
        @type.invoke_callbacks(:level_down, self)
        @type.invoke_callbacks(:regression, self)

      elsif @progression > old_p
        # progression
        @type.invoke_callbacks(:progression, self)

      elsif @progression < old_p
        # regression
        @type.invoke_callbacks(:regression, self)

      end
    end
  end

  # Convert attribute to human readable string and return it
  def to_s
    # TODO
    "attribute-#{@type}(@#{@progression} to #{@level})"
  end

  # Convert user to json representation and return it
  def to_json(*a)
    # TODO
    {
      'json_class' => self.class.name,
      'data'       => {:type_id     => @type.id,
                       :progression => @progression,
                       :level       => @level}
    }.to_json(*a)
  end

  # Create new attribute from json representation
  def self.json_create(o)
    attribute = new(o['data'])
    return attribute
  end

end

# Base attribute class which attribute types derive from.
# Class methods are invoked by subclasses to define their context
class AttributeClass
  # Return new attribute initialized for the specified class
  def self.create_attribute(type_id)
    ac = self.subclasses.find { |ac| ac.id == type_id.intern }
    Attribute.new(:type => ac)
  end

  # id of the attribute class
  def self.id(id = nil)
    @id = id unless id.nil?
    @id
  end

  # description of the attribute class
  def self.description(description = nil)
    @description = description.gsub(/\s+/, " ") unless description.nil?
    @description
  end

  # probably should be moved / referenced elsewhere
  #attr_accessor :logo

  # progression difficulty, amount multiplied by level to
  # increase the difficulty of progressing to the next level
  def self.multiplier(multiplier = nil)
    @multiplier = multiplier unless multiplier.nil?
    @multiplier
  end

  # array of requirements needed by this attribute
  def self.requirements(requirements = nil)
    @requirements = requirements unless requirements.nil?
    @requirements
  end

  # hash of callbacks to invoke on various events including
  # * :progression
  # * :regression
  # * :level_up
  # * :level_down
  def self.callbacks(callbacks = nil)
    unless callbacks.nil?
      @callbacks = callbacks
      @callbacks.each { |k,v| @callbacks[k] = v.is_a?(Array) ? v : [v] }
    end
    @callbacks
  end

  # invoke callbacks registered for the specified event
  def self.invoke_callbacks(event, attribute)
    @callbacks ||= {}
    @callbacks[event].each { |cb|
      cb.call attribute
    } if @callbacks.has_key?(event)
  end
end

end
