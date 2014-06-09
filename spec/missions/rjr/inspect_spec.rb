# missions::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/inspect'
require 'rjr/dispatcher'

module Missions::RJR
  describe "#status", :rjr => true do
    before(:each) do
      Missions::RJR.registry << Omega::Server::Event.new(:id => 'ev1')
      Missions::RJR.registry << Omega::Server::Event.new(:id => 'ev2')

      create(:mission)
      create(:assigned_mission)
      create(:victorious_mission)
      create(:failed_mission)

      dispatch_to @s, Missions::RJR, :INSPECT_METHODS
    end

    it "returns registry.running?" do
      Missions::RJR.registry.should_receive(:running?).and_return(:foo)
      @s.get_status[:running].should == :foo
    end

    it "returns events.size" do
      @s.get_status[:events].should == 2
    end

    it "returns missions.size" do
      @s.get_status[:missions].should == 4
    end

    it "returns active missions.size" do
      @s.get_status[:active].should == 1
    end

    it "returns victorious missions.size" do
      @s.get_status[:victorious].should == 1
    end

    it "returns failed missions.size" do
      @s.get_status[:failed].should == 1
    end
  end # describe "#status"

  describe "#dispatch_missions_rjr_inspect" do
    it "adds missions::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_inspect(d)
      d.handlers.keys.should include("missions::status")
    end
  end

end #module Users::RJR
