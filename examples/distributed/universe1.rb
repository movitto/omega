#!/usr/bin/ruby
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'universe'
require 'rjr/nodes/tcp'
require 'rjr/nodes/local'

RJR::Logger.log_level = ::Logger::DEBUG
RJR::Logger.add_filter proc { |m| !(m =~ /.*moving location.*/ ) }

Omega::Config.load.set_config

server_node = RJR::Nodes::TCP.new   :node_id    => 'universe1',
                                    :host       => 'localhost',
                                    :port       =>  8889

local_node  = RJR::Nodes::Local.new :node_id    => 'universe1_seeder',
                                    :dispatcher => server_node.dispatcher

serve_omega  server_node
create_roles local_node
create_admin local_node
create_user  local_node, 'remote', 'etomer',
             ['create', 'manufactured_entities']

setup_proxies  'universe2' => { :dst      => 'jsonrpc://localhost:8890',
                                :user_id  => 'remote',
                                :password => 'etomer' }

server_node.join
