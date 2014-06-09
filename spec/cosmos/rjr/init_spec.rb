# cosmos/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/init'

module Cosmos::RJR
  describe "#user" do
    it "provides centralized user" do
      rjr = Object.new.extend(Cosmos::RJR)
      rjr.user.should be_an_instance_of Users::User
      rjr.user.valid_login?(Cosmos::RJR.cosmos_rjr_username,
                             Cosmos::RJR.cosmos_rjr_password)

      rjr.user.should equal(rjr.user)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Cosmos::RJR)
      Cosmos::RJR.user.should equal(rjr.user)
    end
  end

  describe "#node" do
    it "provides centralized rjr node" do
      rjr = Object.new.extend(Cosmos::RJR)
      rjr.node.should be_an_instance_of(::RJR::Nodes::Local)
      rjr.node.should equal(rjr.node)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Cosmos::RJR)
      Cosmos::RJR.node.should equal(rjr.node)
    end
  end

  describe "#user_registry" do
    it "provides access to Users::RJR.registry" do
      rjr = Object.new.extend(Cosmos::RJR)
      rjr.user_registry.should == Cosmos::RJR.user_registry
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Cosmos::RJR)
      Cosmos::RJR.user_registry.should equal(rjr.user_registry)
    end
  end

  describe "#registry" do
    it "provides centralized registry" do
      rjr = Object.new.extend(Cosmos::RJR)
      rjr.registry.should be_an_instance_of(Registry)
      rjr.registry.should equal(rjr.registry)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Cosmos::RJR)
      Cosmos::RJR.registry.should equal(rjr.registry)
    end
  end

  describe "#reset" do
    it "clears cosmos registry" do
      Cosmos::RJR.registry << build(:galaxy)
      Cosmos::RJR.registry.entities.size.should > 0
      Cosmos::RJR.reset
      Cosmos::RJR.registry.entities.size.should == 0
    end
  end

  describe "#dispatch_cosmos_rjr_init", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Cosmos::RJR)
    end

    it "dispatches cosmos* in Cosmos::RJR environment" do
      dispatch_cosmos_rjr_init(@d)
      @d.environments[/cosmos::.*/].should  == Cosmos::RJR
    end

    it "adds cosmos rjr modules to dispatcher" do
      @d.should_receive(:add_module).with('cosmos/rjr/create')
      @d.should_receive(:add_module).with('cosmos/rjr/get')
      @d.should_receive(:add_module).with('cosmos/rjr/resources')
      @d.should_receive(:add_module).with('cosmos/rjr/state')
      @d.should_receive(:add_module).with('cosmos/rjr/interconnects')
      dispatch_cosmos_rjr_init(@d)
    end

    it "sets dispatcher on node" do
      dispatch_cosmos_rjr_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_cosmos_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should == 'cosmos'
    end

    it "creates the user" do
      dispatch_cosmos_rjr_init(@d)
      Users::RJR.registry.entity(&with_id(Cosmos::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Cosmos::RJR.user
        lambda{
          dispatch_cosmos_rjr_init(@d)
        }.should_not raise_error
      end
    end

    it "adds additional privileges to user" do
      Cosmos::RJR::PRIVILEGES.each { |p,e|
        Cosmos::RJR.node.should_receive(:invoke).
          with('users::add_privilege',
               "user_role_#{Cosmos::RJR.user.id}",
                p, e)
      }
      Cosmos::RJR.node.should_receive(:invoke).at_least(1).and_call_original
      dispatch_cosmos_rjr_init(@d)
    end

    it "logs in the user using the node" do
      lambda{ # XXX @d.add_module above will have already called dispatch_init
        dispatch_cosmos_rjr_init(@d)
      }.should change{Users::RJR.registry.entities.size}.by(3)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Users::Session) &&
                                       s.user.id == Cosmos::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_cosmos_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end
  end

end # module Cosmos::RJR
