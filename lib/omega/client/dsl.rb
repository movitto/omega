# Omega Client DSL
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega'
require 'omega/client/dsl/base'
require 'omega/client/dsl/util'
require 'omega/client/dsl/users'
require 'omega/client/dsl/cosmos'
require 'omega/client/dsl/manufactured'
require 'omega/client/dsl/missions'

module Omega
  module Client
    # Omega Client DSL, provides many remote access
    # getter / setter methods for omega entities and metadata.
    #
    # @example using the dsl
    #   include Omega::Client::DSL
    #
    #   # create a new user
    #   user 'newuser', 'withpass'
    #
    #   # create a new galaxy/system/planet
    #   galaxy 'Zeus' do |g|
    #     system 'Athena', 'HR1925', :location =>
    #       Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    #         planet 'Aphrodite', :movement_strategy =>
    #           orbit(:speed => 0.1, :e => 0.16, :p => 140,
    #                 :direction => random_axis(:orthogonal_to => [0,1,0]))
    #     end
    #   end
    module DSL
      # Return handle to base dsl instance, use to get/set
      # options such as node/parallel and run operations
      # such as 'join', etc
      def dsl
        @dsl_base ||= Base.new
      end
    end # module DSL
  end # module Client
end # module Omega
