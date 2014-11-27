# Omega Spec Rspec Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/config'
require 'omega/client/mixins'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:all) do
    Omega::Config.load.set_config

    # setup a node to dispatch requests
    @n = RJR::Nodes::Local.new :node_id => 'server'

    # setup a node for factory girl
    fgnode = RJR::Nodes::Local.new
    fgnode.dispatcher.add_module('users/rjr/init')
    fgnode.dispatcher.add_module('motel/rjr/init')
    fgnode.dispatcher.add_module('cosmos/rjr/init')
    fgnode.dispatcher.add_module('missions/rjr/init')
    fgnode.dispatcher.add_module('manufactured/rjr/init')
    $fgnode = fgnode # XXX global
    # TODO set current user ?
  end

  # TODO split out a tag for each subsystem so that
  # different dispatchers can be initialized beforehand
  # and reused by tests in the subsystem (actual registry
  # data will still be cleared with after hook)
  config.before(:each, :rjr => true) do
    # clear/reinit @n
    @n.clear_event_handlers
    @n.node_type = RJR::Nodes::Local::RJR_NODE_TYPE
    @n.message_headers = {}
    @n.dispatcher.clear!
    @n.dispatcher.add_module('users/rjr/init')

    # setup a server which to invoke handlers
    # XXX would like to move instantiation into
    # before(:all) hook & just reinit here,
    @s = Object.new
    @s.extend(Omega::Server::DSL)
    @s.instance_variable_set(:@rjr_node, @n)
    set_header 'source_node', @n.node_id
  end

  config.after(:each) do
    # stop centralized registry loops
    registries =
      [Missions::RJR.registry,
       Manufactured::RJR.registry,
       Motel::RJR.registry,
       Users::RJR.registry]
     registries.each { |r| r.stop.join }

     # reset subsystems
     modules =
      [Users::RJR,    Motel::RJR,
       Missions::RJR, Cosmos::RJR,
       Manufactured::RJR]
     modules.each { |m| m.reset }

    # reset client
    Omega::Client::TrackEntity.clear_entities
    Omega::Client::Trackable.node.handlers = nil
    #Omega::Client::Trackable.instance_variable_set(:@handled, nil) # XXX
  end
end
