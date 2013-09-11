# missions/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/init'

module Missions::RJR
  describe "#user" do
    it "provides centralized user" do
      rjr = Object.new.extend(Missions::RJR)
      rjr.user.should be_an_instance_of Users::User
      rjr.user.valid_login?(Missions::RJR.missions_rjr_username,
                             Missions::RJR.missions_rjr_password)

      rjr.user.should equal(rjr.user)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Missions::RJR)
      Missions::RJR.user.should equal(rjr.user)
    end
  end

  describe "#node" do
    it "provides centralized rjr node" do
      rjr = Object.new.extend(Missions::RJR)
      rjr.node.should be_an_instance_of(::RJR::Nodes::Local)
      rjr.node.should equal(rjr.node)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Missions::RJR)
      Missions::RJR.node.should equal(rjr.node)
    end
  end

  describe "#user_registry" do
    it "provides access to Users::RJR.registry" do
      rjr = Object.new.extend(Missions::RJR)
      rjr.user_registry.should == Missions::RJR.user_registry
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Missions::RJR)
      Missions::RJR.user_registry.should equal(rjr.user_registry)
    end
  end

  describe "#registry" do
    it "provides centralized registry" do
      rjr = Object.new.extend(Missions::RJR)
      rjr.registry.should be_an_instance_of(Registry)
      rjr.registry.should equal(rjr.registry)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Missions::RJR)
      Missions::RJR.registry.should equal(rjr.registry)
    end
  end

  describe "#reset" do
    it "clears missions registry" do
      Missions::RJR.registry << build(:mission, :creator => build(:user))
      Missions::RJR.registry.entities.size.should > 0
      Missions::RJR.reset
      Missions::RJR.registry.entities.size.should == 0
    end
  end

  describe "#manufactured event" do
    before(:each) do
      dispatch_to @s, Missions::RJR, :CALLBACK_METHODS
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.manufactured_event 'anything'
        }.should raise_error(PermissionError)
      end
    end

    it "creates new manufactured event" do
      sh = build(:ship)
      lambda {
        @s.manufactured_event 'attacked', sh
      }.should change{Missions::RJR.registry.entities.size}.by(1)
      Missions::RJR.registry.entities.last.id.should == "#{sh.id}_attacked"
    end

    it "returns nil" do
      @s.manufactured_event.should be_nil
    end
  end

  describe "#dispatch_missions_rjr_init" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Missions::RJR)
    end

    it "dispatches missions* in Missions::RJR environment" do
      dispatch_missions_rjr_init(@d)
      @d.environments[/missions::.*/].should  == Missions::RJR
    end

    it "adds missions rjr modules to dispatcher"

    it "sets dispatcher on node" do
      dispatch_missions_rjr_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_missions_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should == 'missions'
    end

    it "creates the user" do
      dispatch_missions_rjr_init(@d)
      Users::RJR.registry.entity(&with_id(Missions::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Missions::RJR.user
        lambda{
          dispatch_missions_rjr_init(@d)
        }.should_not raise_error
      end
    end

    it "adds additional privileges to user"

    it "logs in the user using the node" do
      lambda{ # XXX @d.add_module above will have already called dispatch_init
        dispatch_missions_rjr_init(@d)
      }.should change{Users::RJR.registry.entities.size}.by(3)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Users::Session) &&
                                       s.user.id == Missions::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_missions_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end

    it "add manufactured::event_occurred callback to dispatcher"
    it "executes manufactured::event_occurred callbacks in Missions::RJR env"
  end

end # module Missions::RJR
