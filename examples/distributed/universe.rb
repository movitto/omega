# Various methods to w/ the distributed example
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/roles'
require 'omega/server/config'

def serve_omega(node)
  node.dispatcher.add_module('users/rjr/init')
  node.dispatcher.add_module('motel/rjr/init')
  node.dispatcher.add_module('cosmos/rjr/init')
  node.dispatcher.add_module('stats/rjr/init')
  node.dispatcher.add_module('manufactured/rjr/init')
  node.dispatcher.add_module('missions/rjr/init')
  node.listen
end

def create_roles(node)
  Omega::Roles::ROLES.keys.collect { |id|
    role = Users::Role.new :id => id
    Omega::Roles::ROLES[id].each { |pe|
      role.add_privilege pe[0], pe[1]
    }
    node.invoke('users::create_role', role)
  }
end

def create_admin(node)
  admin = Users::User.new :id                => 'admin',
                          :password          => 'nimda',
                          :registration_code => nil
  node.invoke('users::create_user', admin)
  node.invoke('users::add_role',    admin.id, 'superadmin')
end

def create_user(node, user_id, password, *privileges)
  remote = Users::User.new :id                => user_id,
                           :password          => password,
                           :registration_code => nil
  node.invoke('users::create_user', remote)

  privileges.each { |pe|
    priv = pe.first
    entity = pe.size > 1 ? pe[1] : nil

    node.invoke('users::add_privilege', "user_role_#{user_id}", priv, entity)
  }
end

def setup_proxies(proxies={})
  config = Omega::Config.new :proxy_to => proxies
  Omega::Server::ProxyNode.set_config config
end
