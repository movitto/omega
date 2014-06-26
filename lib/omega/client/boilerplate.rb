# Omega client boilerplate
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'rubygems'

require 'omega'
require 'omega/client/dsl'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

# TODO env/other var specifying which transport used, node_id, & other params?
require 'rjr/nodes/tcp'
dsl.rjr_node = RJR::Nodes::TCP.new(:node_id =>    'client',
                                   :host    => 'localhost',
                                   :port    =>      '9090')

# if omega is running on non-default host/port, uncomment & set here
# TODO read from config?
#dsl.node.endpoint = 'jsonrpc://localhost:8181'
