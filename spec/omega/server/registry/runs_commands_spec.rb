# Omega Server Registry RunsCommands Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe RunsCommands do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
    end

    describe "#run_commands" do
      before(:each) do
        @c = Command.new
        @registry.stub(:entities).and_return([@c])
      end

      it "sets registry on command" do
        @c.should_receive(:registry=).with(@registry)
        @registry.send :run_commands
      end

      it "sets node on command" do
        @c.should_receive(:node=).with(@registry.node)
        @registry.send :run_commands
      end

      context "first hooks not run" do
        it "runs first hooks" do
          @c.should_receive(:run_hooks).with(:first)
          @registry.send :run_commands
        end
      end

      context "first hooks previously run" do
        it "does not runs first hooks" do
          @c.run_hooks :first
          @c.should_not_receive(:run_hooks).with(:first)
          @registry.send :run_commands
        end
      end

      it "runs before hooks" do
        @c.should_receive(:run_hooks).with(:first)
        @c.should_receive(:run_hooks).with(:before)
        @registry.send :run_commands
      end

      context "command should run" do
        before(:each) do
          @c.should_receive(:should_run?).and_return(true)
        end

        it "runs command" do
          @c.should_receive(:run!)
          @registry.send :run_commands
        end

        it "runs after hooks" do
          @c.should_receive(:run_hooks).with(:first)
          @c.should_receive(:run_hooks).with(:before)
          @c.should_receive(:run_hooks).with(:after)
          @registry.send :run_commands
        end
      end

      context "command should not run" do
        before(:each) do
          @c.should_receive(:should_run?).and_return(false)
        end

        it "does not run command" do
          @c.should_not_receive(:run!)
          @registry.send :run_commands
        end

        it "does not run after hooks" do
          @c.should_not_receive(:run_hooks).with(:after)
          @registry.send :run_commands
        end
      end

      context "command should be removed" do
        before(:each) do
          @c.should_receive(:remove?).and_return(true)
        end

        it "runs last hooks" do
          @c.should_receive(:run_hooks).with(:first)
          @c.should_receive(:run_hooks).with(:before)
          @c.should_receive(:run_hooks).with(:after)
          @c.should_receive(:run_hooks).with(:last)
          @registry.send :run_commands
        end

        it "deletes command" do
          @registry.should_receive(:delete)
          @registry.send :run_commands
        end
      end

      it "catches errors during command hooks" do
        @c.should_receive(:run_hooks).and_raise(Exception)
        lambda{
          @registry.send :run_commands
        }.should_not raise_error
      end

      it "catches errors during command" do
        @c.should_receive(:run!).and_raise(Exception)
        lambda{
          @registry.send :run_commands
        }.should_not raise_error
      end

      it "returns default command poll" do
        @registry.send(:run_commands).should == Registry::DEFAULT_COMMAND_POLL
      end
    end

    describe "#check_command" do
      it "removes all entities w/ the specified command id except last" do
        c1 = Command.new :id => 'cid', :exec_rate => 5
        c2 = Command.new :id => 'cid', :exec_rate => 15
        @registry << c1
        @registry << c2
        @registry.send :check_command, Command.new(:id => 'cid')
        res = @registry.entities { |e| e.id == 'cid' }

        res.size.should == 1
        res.first.exec_rate.should == 15
      end
    end
  end # describe RunsCommands
end # module Registry
end # module Server
end # module Omega
