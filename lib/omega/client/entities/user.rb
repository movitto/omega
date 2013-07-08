#!/usr/bin/ruby
# omega client user entities tracker
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/mixins'
require 'users/user'

module Omega
  module Client
    # Omega client Users::User tracker
    class User
      include Trackable

      entity_type  Users::User
      get_method   "users::get_entity"

      # TODO how to detect & retrieve newly created ships
      # & stations from the server?
      def ships
        @ships    ||= Omega::Client::Ship.owned_by(self.id)
      end

      def stations
        @stations ||= Omega::Client::Station.owned_by(self.id)
      end

      def self.login(user_id, password)
        user = Users::User.new(:id => user_id, :password => password)
        session = node.invoke('users::login', user)
        node.rjr_node.message_headers['session_id'] = session.id
        nil
      end
    end
  end
end
