# Omega Client DSL Utility Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/constraints'

module Omega
  module Client
    module DSL
      # Generate an return a random uuid
      #
      # @see Motel.gen_uuid
      def gen_uuid
        Motel.gen_uuid
      end

      # Generate an return a new random {Cosmos::Resource}
      #
      # @see Omega::Resources.rand_resource
      def rand_resource
        Omega::Resources.random
      end

      # Generate an return a new random {Motel::Location},
      # using the specified arguments
      #
      # @see Motel::Location.random
      def rand_location(args={})
        Motel::Location.random args
      end
      alias :rand_loc :rand_location

      # Wrapper around Motel.random_axis
      def random_axis(*args)
        Motel.random_axis *args
      end
      alias :rand_axis :random_axis

      # Negate the specified coords
      def neg(*coords)
        coords.collect { |c| c * -1 }
      end

      # Utility wrapper to simply return a new location
      def loc(x,y=nil,z=nil)
        return Motel::Location.new(x)if x.is_a?(Hash) && y.nil? && z.nil?
        Motel::Location.new :x => x, :y => y, :z => z
      end

      # Invoke request using the DSL node / endpoint
      def invoke(*args)
        dsl.invoke *args
      end

      # Invoke notification using the DSL node / endpoint
      def notify(*args)
        dsl.notify *args
      end

      # Log specified user into the server
      #
      # @param [String] user_id string id of the user to login
      # @param [String] password password of the user to login
      # @see Omega::Client::User.login
      def login(user_id, password)
        user = Users::User.new(:id => user_id,
                               :password => password)
        @session = invoke('users::login', user)
        dsl.node.rjr_node.message_headers['session_id'] = @session.id
      end

      # Log the user out of the server
      def logout
        invoke('users::logout', @session.id)
        @session = nil
        dsl.node.rjr_node.message_headers['session_id'] = nil
      end
    end # module DSL
  end # module Client
end # module Omega
