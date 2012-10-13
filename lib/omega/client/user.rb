#!/usr/bin/ruby
# omega client user tracker
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'

module Omega
  module Client
    class User < Entity
      attr_accessor :ships
      attr_accessor :stations

      def self.get_method
        "users::get_entity"
      end

      def self.entity_type
        "Users::User"
      end

      def self.login(node, username, password)
        Omega::Client::Tracker.node = node

        session = Omega::Client::Tracker.invoke_request('users::login',
                    Users::User.new(:id => username, :password => password))
        Omega::Client::Tracker.message_headers['session_id'] = session.id

        return get(username)
      end

      def get_associated
        # ships / stations may have been constructed
        # TODO create better way to just get new ones
        lships = Omega::Client::Ship.owned_by self.id
        lstats = Omega::Client::Station.owned_by self.id
        Tracker.synchronize{
          @ships    = lships
          @stations = lstats
        }
      end
    end
  end
end
