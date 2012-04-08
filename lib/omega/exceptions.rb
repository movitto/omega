# Helper module to define common exceptions
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Omega

class BaseError < RuntimeError
  def intialize(msg)
    super(msg)
  end
end

class DataNotFound < BaseError
  def initialize(msg)
    super(msg)
  end
end

class PermissionError < BaseError
  def initialize(msg)
    super(msg)
  end
end

class OperationError < BaseError
  def initialize(msg)
    super(msg)
  end
end

class RPCError < BaseError
  def initialize(msg)
    super(msg)
  end
end

end # module Omega
