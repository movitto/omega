#!/usr/bin/ruby
# omega client user tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Client
    class User < Entity
      def self.get_method
        "users::get_entity"
      end

      def self.entity_type
        "Users::User"
      end

      def self.login(node, username, password)
        Omega::Client::Tracker.node = node

        session = Omega::Client::Tracker.invoke_request('omega-queue','users::login',
                               Users::User.new(:id => 'admin', :password => 'nimda'))
        Omega::Client::Tracker.message_headers['session_id'] = session.id

        return get('admin')
      end

    end
  end
end
