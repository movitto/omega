# Base Registry HasState Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Omega
module Server
module Registry
  module HasState
    attr_accessor :backup_excludes

    private

    def init_state
      @backup_excludes ||= []
    end

    public

    def exclude_from_backup(cl)
      @backup_excludes << cl
    end

    # Save state
    def save(io)
      init_registry
      @lock.synchronize {
        @entities.each { |entity|
          should_exclude = @backup_excludes.any? { |exclude_class|
                                    entity.kind_of?(exclude_class) }
          io.write entity.to_json + "\n" unless should_exclude
        }
      }
    end

    # Restore state
    def restore(io)
      init_registry
      io.each_line { |json|
        self << RJR::JSONParser.parse(json)
      }
    end
  end # module HasState
end # module Registry
end # module Server
end # module Omega
