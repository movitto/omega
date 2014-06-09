# manufactured entity validation
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'manufactured/rjr/validate/attributes'

module Manufactured::RJR
  # callback to validate user attributes upon entity creation
  #
  # Defined here as it requires access to node, added to registry below
  validate_user_attributes = proc { |entities, entity|
    validated = true
    begin
      @manu_validator ||= Object.new.extend(Manufactured::RJR) # XXX
      @manu_validator.validate_user_attributes(entities, entity)
    rescue ValidationError => e
      validated = false
    end
    validated
  }

  VALIDATE_METHODS = {:validate_user_attributes => validate_user_attributes}
end # module Manufactured::RJR

def dispatch_manufactured_rjr_validate(dispatcher)
  m = Manufactured::RJR::VALIDATE_METHODS
  registry = Manufactured::RJR.registry

  # register entity validation method w/ registry
  unless registry.validation_methods.include?(m[:validate_user_attributes])
    registry.validation_callback &m[:validate_user_attributes]
  end
end
