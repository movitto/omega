# manufactured::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/inspect'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#command" do
    before(:each) do
      dispatch_to @s, Manufactured::RJR, :INSPECT_METHODS
    end

    it "retrieves command by id" do
      cmd = Omega::Server::Command.new(:id => 'cmd1', :exec_rate => 10)
      Manufactured::RJR.registry << cmd
      rc = @s.get_cmd 'cmd1'
      rc.exec_rate.should == 10
    end
  end

  describe "#status" do
    before(:each) do
      dispatch_to @s, Manufactured::RJR, :INSPECT_METHODS
    end

    it "returns registry.running?" do
      Manufactured::RJR.registry.should_receive(:running?).and_return(:foo)
      @s.get_status[:running].should == :foo
    end

    it "returns ships.size" do
      Manufactured::RJR.registry << build(:valid_ship)
      Manufactured::RJR.registry << build(:valid_ship)
      @s.get_status[:ships].should == 2
    end

    it "returns stations.size" do
      create(:valid_station)
      create(:valid_station)
      @s.get_status[:stations].should == 2
    end

    it "returns all commands" do
      Manufactured::RJR.registry << Omega::Server::Command.new(:id => 'cmd1')
      Manufactured::RJR.registry << Omega::Server::Command.new(:id => 'cmd2')
      cmds = @s.get_status[:commands]
      cmd_ids = cmds['Omega::Server::Command'].collect { |c| c } # TODO test cmd class keys
      cmd_ids.should include('command-cmd1')
      cmd_ids.should include('command-cmd2')
    end
  end # describe "#status"

  describe "#dispatch_manufactured_rjr_inspect" do
    it "adds manufactured::command to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_inspect(d)
      d.handlers.keys.should include("manufactured::command")
    end

    it "adds manufactured::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_inspect(d)
      d.handlers.keys.should include("manufactured::status")
    end
  end

end #module Users::RJR
