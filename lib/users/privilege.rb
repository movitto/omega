# Users module privilege definition
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users

class Privilege
  attr_reader :id
  attr_reader :entity_id

  def initialize(args = {})
    @id        = args['id']         || args[:id]
    @entity_id = args['entity_id']  || args[:entity_id]
  end

  def ==(privilege)
    @id == privilege.id && @entity_id == privilege.entity_id
  end

end

class Role
  attr_accessor :id
  attr_accessor :privilege
  attr_accessor :entity

  def initialize(args = {})
    @id        = args['id']         || args[:id]
    @entity    = args['entity_id']  || args[:entity_id]
    @privilege = args['privilege']  || args[:privilege]
  end
end


end
