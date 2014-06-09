# Omega Server DSL attribute operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
  module Server
    module DSL
      # Check if the user has the specified attribute
      def check_attribute(args = {})
        query = 'users::has_attribute?', args[:user_id], args[:attribute_id]
        query << args[:level] if args.has_key?(:level)
        args[:node].invoke(*query)
      end

      # Require the user to have the specified attribute, else raise PermissionErr
      def require_attribute(args = {})
        raise Omega::PermissionError,
          "require_attribute(#{args})" unless check_attribute(args)
      end
    end # module DSL
  end # module Server
end # module Omega
