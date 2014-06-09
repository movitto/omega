# System Jump Event class tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/events/system_jump'
require 'manufactured/event_handler'

module Manufactured
module Events
describe SystemJump do
  describe "#initialize" do
    before(:each) do
      @sys = Cosmos::Entities::SolarSystem.new
      @ship = Manufactured::Ship.new :id => 'sh1'
    end

    it "sets old_system" do
      event = SystemJump.new :old_system => @sys, :entity => @ship
      event.old_system.should == @sys
    end

    it "sets entity" do
      event = SystemJump.new :entity => @ship
      event.entity.should == @ship
    end

    it "sets event id" do
      event = SystemJump.new :entity => @ship
      event.id.should == "#{SystemJump::TYPE}-#{@ship.id}"
    end

    it "sets event type" do
      event = SystemJump.new :entity => @ship
      event.type.should == SystemJump::TYPE.to_s
    end
  end

  describe "#event_args" do
    it "returns [entity, old_system]" do
      sys   = Cosmos::Entities::SolarSystem.new
      ship  = Manufactured::Ship.new
      event = SystemJump.new :old_system => sys, :entity => ship
      event.event_args.should == [ship, sys]
    end
  end

  describe "#trigger_handler?" do
    before(:each) do
      @old_sys  = Cosmos::Entities::SolarSystem.new :id => 'sys1'
      @new_sys  = Cosmos::Entities::SolarSystem.new :id => 'sys2'
      @ship     = Manufactured::Ship.new :id => 'ship1', :solar_system => @new_sys
      @sj       = SystemJump.new :old_system => @old_sys, :entity => @ship
    end

    context "handler 'to' <new_system>" do
      it "returns true" do
        to_new_sys = Manufactured::EventHandler.new :event_args => ['to', @new_sys.id]
        @sj.trigger_handler?(to_new_sys).should be_true
      end
    end

    context "handler 'to' <anything_else>" do
      it "returns false" do
        to_old_sys = Manufactured::EventHandler.new :event_args => ['to', @old_sys.id]
        @sj.trigger_handler?(to_old_sys).should be_false
      end
    end

    context "handler 'from' <old_system>" do
      it "returns true" do
        from_old_sys = Manufactured::EventHandler.new :event_args => ['from', @old_sys.id]
        @sj.trigger_handler?(from_old_sys).should be_true
      end
    end

    context "handler 'from' <anything_else>" do
      it "returns false" do
        from_new_sys = Manufactured::EventHandler.new :event_args => ['from', @new_sys.id]
        @sj.trigger_handler?(from_new_sys).should be_false
      end
    end

    context "invalid handler specifier" do
      it "returns false" do
        other = Manufactured::EventHandler.new :event_args => ['anything']
        @sj.trigger_handler?(other).should be_false
      end
    end
  end

  describe "#to_json" do
    it "returns the event in json format" do
      sys   = Cosmos::Entities::SolarSystem.new :id => 'sys1'
      ship  = Manufactured::Ship.new :id => 'sh1'
      sj = SystemJump.new :old_system => sys, :entity => ship

      j = sj.to_json
      j.should include('"json_class":"Manufactured::Events::SystemJump"')
      j.should include('"json_class":"Cosmos::Entities::SolarSystem"')
      j.should include('"id":"sys1"')
      j.should include('"id":"sh1"')
    end
  end

end # describe RegisteredUser
end # module Events
end # module Users
