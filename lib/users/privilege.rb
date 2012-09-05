# Users module privilege definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

# Access control mechanism entailing unique identifier
# describing the prvilege and optionally the id of
# the entity which it applies to.
#
# Operations may require privileges to invoke and
# users may be assigned privileges.
class Privilege
  # Identifier of privilege this represents
  attr_reader :id

  # Identifier of entity which this privilege applies to
  attr_reader :entity_id

  # Privilege initializer
  # @param [Hash] args hash of options to initialize privilege with
  # @option args [String] :id,'id' id to assign to the privilege
  # @option args [String] :entity_id,'entity_id' entity_id to assign to the privilege
  def initialize(args = {})
    @id        = args['id']         || args[:id]
    @entity_id = args['entity_id']  || args[:entity_id]
  end

  # Return boolean indicating if local attributes match those of specified privilege
  #
  # @param [Users::Privilege] privilege privilege which to compare
  # @return [true,false] indicating if privileges are equal
  def ==(privilege)
    @id == privilege.id && @entity_id == privilege.entity_id
  end

  # Convert privilege to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:id => id, :entity_id => entity_id}
    }.to_json(*a)
  end

  # Create new privilege from json representation
  def self.json_create(o)
    privilege = new(o['data'])
    return privilege
  end

end
end
