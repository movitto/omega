# Omega Spec Cosmos Entity
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module OmegaTest
  class CosmosEntity
    include Cosmos::Entity

    PARENT_TYPE = 'CosmosEntity'
    CHILD_TYPES = ['CosmosEntity']

    def initialize(args = {})
      init_entity(args)
    end

    def valid?
      entity_valid?
    end
  end

  class CosmosSystemEntity < CosmosEntity
    include Cosmos::SystemEntity
  end
end
