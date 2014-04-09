# Omega Client DSL Base Interface
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/node'

module Omega
  module Client
    module DSL
      # Internal helper, used to track dsl state
      class Base
        include Omega::Client::DSL

        # override DSL::dsl, return self
        def dsl
          self
        end

        # internally managed client node
        def node
          @node ||= Client::Node.new
        end

        # get underlying rjr_node
        def rjr_node
          self.node.rjr_node
        end

        # set underlying rjr node
        def rjr_node=(val)
          self.node.rjr_node = val
        end

        # Proxy invoke to client node
        def invoke(*args)
          self.node.invoke *args
        end

        # Proxy notify to client node
        def notify(*args)
          self.node.notify *args
        end

        # Boolean indicating if dsl should be run in parallel
        attr_accessor :parallel

        # Threads being managed
        attr_accessor :workers

        # Wait until all workers complete
        def join
          @workers.each { |w| w.join }
        end

        # Set attributes and run block w/ params (via worker if parallel is true)
        #
        # TODO use thread pool for this?
        def run(params, attrs={}, &bl)
          if @parallel
            @workers <<  Thread.new(params, attrs) { |params,attrs|
              # create new base instance and run
              # block there to safely set attributes
              b = Base.new
              b.rjr_node = self.node.rjr_node
              b.run params, attrs, &bl
            }

          else
            attrs.each { |k,v| self.instance_variable_set("@#{k}".intern, v)}
            instance_exec params, &bl unless bl.nil?
            attrs.each { |k,v| self.instance_variable_set("@#{k}".intern, nil)}
          end
        end

        def initialize
          @parallel = false
          @workers  = []
        end
      end
    end # module DSL
  end # module Client
end # module Omega
