# Users User HasAttributes Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'users/attribute'

module Users

# Mixed into User, provides attribute capabilities
module HasAttributes
  # List of attributes currently owned by the user
  attr_accessor :attributes

  # Initialize default attributes / attributes from arguments
  def attributes_from_args(args)
    attr_from_args args, :attributes => nil

    @attributes.each { |attr| attr.user = self } if @attributes
  end

  # Update attributes from specified user
  def update_attributes(user)
    @attributes = user.attributes unless user.attributes.nil?
  end

  # Updates user attribute with specified change
  #
  # @param [String] attribute_id id of attribute to update
  # @param [Integer,Float] change positive/negative amount to change attribute progression by
  def update_attribute!(attribute_id, change)
    @attributes ||= []
    attribute = @attributes.find { |a| a.type.id.to_s == attribute_id.to_s }

    if attribute.nil?
      # TODO also need to assign permissions to view attribute to user
      attribute = AttributeClass.create_attribute(:type_id => attribute_id.intern)
      attribute.user = self
      raise ArgumentError, "invalid attribute #{attribute_id}" if attribute.type.nil?
      @attributes << attribute
    end

    attribute.update!(change)
    attribute
  end

  # Return boolean indicating if the user has the specified attribute
  # at an optional minimum level
  def has_attribute?(attribute_id, level = nil)
    @attributes ||= []
    !@attributes.find { |a| a.type.id == attribute_id.intern &&
                           (level.nil? || a.level >= level ) }.nil?
  end

  # Return attribute w/ the specified id, else null
  def attribute(attribute_id)
    @attributes ||= []
    @attributes.find { |a| a.type.id == attribute_id.intern }
  end

  # Return attributes in json format
  def attributes_json
    {:attributes => attributes}
  end
end # module HasRoles
end # module Users
