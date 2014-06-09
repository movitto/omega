# missions::add_hook rjr definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'missions/rjr/init'
require 'missions/event_handler'

module Missions::RJR

# TODO remove_hook method

# create a server side hook
add_hook = proc { |handler|
  # require create on missions_hooks
  require_privilege :registry  => user_registry,
                    :privilege => 'create',
                    :entity    => 'missions_hooks'

  # ensure valid event handler
  raise ValidationError, handler unless handler.is_a?(Missions::EventHandlers::DSL)

  # resolve missions dsl references
  Missions::DSL::Client::Proxy.resolve(:event_handler => handler)

  # add handler to registry
  registry << handler

  # return nil
  nil
}

HOOKS_METHODS = { :add_hook => add_hook }

end # module Missions::RJR

def dispatch_missions_rjr_hooks(dispatcher)
  m = Missions::RJR::HOOKS_METHODS
  dispatcher.handle 'missions::add_hook', &m[:add_hook]
end
