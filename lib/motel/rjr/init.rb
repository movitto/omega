# Initialize the motel subsystem
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/registry'
require 'omega/exceptions'
require 'omega/server/dsl'

require 'users/rjr/init'

module Motel::RJR
  include Motel
  include Omega#::Exceptions
  include Omega::Server::DSL

  def self.user_registry
    Users::RJR.registry
  end

  def user_registry
    Motel::RJR.user_registry
  end

  def self.registry
    @registry ||= Motel::Registry.new
  end

  def registry
    Motel::RJR.registry
  end

  def self.reset
    Motel::RJR.registry.clear!
  end
end

def dispatch_motel_rjr_init(dispatcher)
  Motel::RJR.registry.start

  # run motel method handlers in motel::rjr module
  dispatcher.env /motel::.*/, Motel::RJR
  dispatcher.add_module('motel/rjr/create')
  dispatcher.add_module('motel/rjr/get')
  dispatcher.add_module('motel/rjr/update')
  dispatcher.add_module('motel/rjr/delete')
  dispatcher.add_module('motel/rjr/track')
  dispatcher.add_module('motel/rjr/remove_callbacks')
  dispatcher.add_module('motel/rjr/state')
end
