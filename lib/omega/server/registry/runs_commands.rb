# Base Registry RunsCommands Mixin
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/command'

module Omega
module Server
module Registry
  module RunsCommands
    # Default time command loop thread sleeps between command cycles
    DEFAULT_COMMAND_POLL = 0.5

    private

    # Run commands registered in the local registry
    #
    # Optional internal helper method, utilize like so:
    #   run { run_commands }
    def run_commands
      self.entities { |e| e.kind_of?(Command) }.
        each   { |cmd|
          begin
            # registry/node isn't serialized w/ other
            # cmd json, set on each cmd run
            cmd.registry = self
            cmd.node = self.node

            cmd.run_hooks :first  unless cmd.ran_first_hooks
            cmd.run_hooks :before

            if cmd.should_run?
              cmd.run!
              cmd.run_hooks :after
            end

            # subsequent commands w/ the same id will break
            # system if command updated is removed from
            # the registry here, use check_command below
            # to mitigate this
            if cmd.remove?
              cmd.run_hooks :last

              # TODO introduce optional command 'graveyard' at some point
              # to store history of previously executed commands

              # FIXME if command should be removed but was never run this
              # won't catch, need to handle this case?

              delete { |e| e.kind_of?(Command) && # find registry cmd and
                           e.id == cmd.id      && # ensure it hasn't been
                           e.last_ran_at }        # swapped out / already deleted

            else
              self << cmd
            end


          rescue Exception => err
            RJR::Logger.warn "error in command #{cmd}: #{err} : #{err.backtrace.join("\n")}"
          end
        }

      DEFAULT_COMMAND_POLL
    end

    # Check commands/enforce unique id's
    #
    # Optional internal helper method, utilize like so:
    #   on(:added) { |c| check_command(c) if c.kind_of?(Omega::Server::Command) }
    def check_command(command)
      @lock.synchronize {
        rcommands = @entities.select { |e|
          e.kind_of?(Command) && e.id == command.id
        }
        if rcommands.size > 1
          # keep last one that was added
          ncommand = rcommands.last

          # unless one has an added_at timestamp at at later date
          rcommands.sort! { |c1,c2| c1.added_at <=> c2.added_at }
          ncommand = rcommands.last if rcommands.last.added_at > ncommand.added_at

          @entities -= rcommands
          @entities << ncommand
        end
      }
    end
  end # module RunsCommands
end # module Registry
end # module Server
end # module Omega
