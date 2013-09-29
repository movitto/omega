# Omega Client Node
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/config'

module Omega
  module Client
    class Node
      # Server endpoint
      attr_accessor :endpoint

      # Node to use w/ server communications
      attr_accessor :rjr_node
      def rjr_node=(val)
        @rjr_node = val
        @rjr_node.message_headers['source_node'] = @rjr_node.node_id

        # load any accessible config
        config = Omega::Config.load :node_id  => 'omega',
                                    :tcp_host => 'localhost',
                                    :tcp_port =>  8181
        self.endpoint=
          case rjr_node.class::RJR_NODE_TYPE
            when :amqp then "#{config.node_id}-queue"
            when :tcp  then "jsonrpc://#{config.tcp_host}:#{config.tcp_port}"
            when :ws   then "jsonrpc://#{config.ws_host}:#{config.ws_port}"
            else nil
          end
      end

      # Invoke request using the DSL node / endpoint
      def invoke(*args)
        args.unshift @endpoint unless @endpoint.nil?
        @rjr_node.invoke *args
      end

      # Invoke notification using the DSL node / endpoint
      def notify(*args)
        args.unshift @endpoint unless @endpoint.nil?
        @rjr_node.notify *args
      end

      attr_accessor :handlers

      def handles?(rjr_method)
        !@handlers.nil? && @handlers.keys.include?(rjr_method)
      end

      def handle(rjr_method, &bl)
        @handlers ||= Hash.new() { |h,k| h[k] = [] }

        unless @handlers.keys.include?(rjr_method)
          # add handler to rjr_node
          client_node = self
          @rjr_node.dispatcher.handle(rjr_method) { |*args|
            client_node.handlers[rjr_method].each { |h| h.call *args }
            nil
          }
        end

        @handlers[rjr_method] << bl 
      end

    end
  end
end
