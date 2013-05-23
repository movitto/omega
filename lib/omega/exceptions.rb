# Helper module to define common exceptions
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega

# Base omega exception, all custom exceptions are derived from this
class BaseError < RuntimeError
  def intialize(msg)
    super(msg)
  end
end

# Raised if user requests data which cannot be found
class DataNotFound < BaseError
  def initialize(filter)
    super("entity specified by #{filter} not found")
  end
end

# Raised if user requests data which the do not have sufficient
# permissions on
class PermissionError < BaseError
  def initialize(msg)
    super(msg)
  end
end

# Raised if there was a problem invoking a requested operation
class OperationError < BaseError
  def initialize(msg)
    super(msg)
  end
end

# Raise if user data cannot be validated
class ValidationError < BaseError
  def initialize(entity, type='entity')
    super("#{entity} must be a valid #{type}")
  end
end

end # module Omega
