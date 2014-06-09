# Omega Server DSL entities/entity operations
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'omega/server/command'

module Omega
  module Server
    module DSL
      # Require entity to be in the state specified by the given callback.
      # Raise ValidationError otherwise
      def require_state(entity, msg=nil, &validation)
        unless validation.call entity
          msg ||= "#{entity} did not pass validation"
          raise ValidationError, msg
        end
      end

      # Generate a selector from block which is called to determine selection
      def matching(&bl)
        proc { |e| bl.call(e) }
      end

      # Generate a selector which compares entity w/ specified attribute
      def with(attr, val)
        proc { |e| e.respond_to?(attr.intern) && e.send(attr.intern) == val }
      end

      # Generate a selector which matches entity w/ specified id
      def with_id(eid)
        with(:id, eid)
      end

      # Generate a selector which matches entities _not_
      # descending from the Omega::Server namespace
      def in_subsystem
        proc { |e|
          !e.class.ancestors.any? { |cl|
            cl.to_s =~ /Omega::Server::.*/
          }
        }
      end

      # Return boolean indicating if specified entity is a command
      def is_cmd?(entity)
        entity.kind_of?(Omega::Server::Command)
      end

    end # module DSL
  end # module Server
end # module Omega
