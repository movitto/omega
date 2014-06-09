# Omega Server DSL node operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Server
    module DSL
      # Get/set node used in operations
      attr_accessor :node

      # Return bool indicating if node is of given type
      def is_node?(type)
        !@rjr_node.nil? && @rjr_node.node_type == type::RJR_NODE_TYPE
      end

      # Require rjr node of the specified type, else raise a permission err
      # TODO
      #def require_node!(type)
      #end

      # Return bool indicating if request has come in over a persistent transport
      def persistent_transport?
        @rjr_node.persistent?
      end

      # Raise error is transport is not persistent
      def require_persistent_transport!(err=nil)
        err = "request must come in on persistent transport" if err.nil?
        raise OperationError, err unless persistent_transport?
      end

      # Return bool indiciating if source node is valid / can be used by Omega
      def from_valid_source?
         @rjr_headers['source_node'].is_a?(String) &&
        !@rjr_headers['source_node'].empty?
      end

      # Raise error if source node is not valid
      def require_valid_source!(err=nil)
        err = "source node is required" if err.nil?
        raise PermissionError, err unless from_valid_source?
      end
    end # module DSL
  end # module Server
end # module Omega
