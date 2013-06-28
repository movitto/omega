# manufactured/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/init'

module Manufactured::RJR
  describe "#user" do
    it "provides centralized user" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.user.should be_an_instance_of Users::User
      rjr.user.valid_login?(Manufactured::RJR.manufactured_rjr_username,
                             Manufactured::RJR.manufactured_rjr_password)

      rjr.user.should equal(rjr.user)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.user.should equal(rjr.user)
    end
  end

  describe "#node" do
    it "provides centralized rjr node" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.node.should be_an_instance_of(::RJR::Nodes::Local)
      rjr.node.should equal(rjr.node)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.node.should equal(rjr.node)
    end
  end

  describe "#user_registry" do
    it "provides access to Users::RJR.registry" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.user_registry.should == Manufactured::RJR.user_registry
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.user_registry.should equal(rjr.user_registry)
    end
  end

  describe "#registry" do
    it "provides centralized registry" do
      rjr = Object.new.extend(Manufactured::RJR)
      rjr.registry.should be_an_instance_of(Registry)
      rjr.registry.should equal(rjr.registry)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Manufactured::RJR)
      Manufactured::RJR.registry.should equal(rjr.registry)
    end
  end

  describe "#reset" do
    it "clears manufactured registry" do
      sys = create(:solar_system)
      loc = create(:location, :parent_id => sys.location.id)
      Manufactured::RJR.registry << build(:valid_ship, :location => loc, :solar_system => sys)
      Manufactured::RJR.registry.safe_exec { |entities| entities.size.should > 0 }
      Manufactured::RJR.reset
      Manufactured::RJR.registry.safe_exec { |entities| entities.size.should == 0 }
    end
  end

  describe "#motel_event" do
    context "not local node" do
      it "raises PermissionError"
    end

    it "updates entity from location"

    it "sets next movement strategy" # ?

    context "location stopped" do
      it "remove motel callbacks"
    end

    it "returns nil"
  end

  describe "#dispatch_manufactured_rjr_init" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Manufactured::RJR)
    end

    it "dispatches manufactured* in Manufactured::RJR environment" do
      dispatch_manufactured_rjr_init(@d)
      @d.environments[/manufactured::.*/].should  == Manufactured::RJR
    end

    it "adds manufactured rjr modules to dispatcher"

    it "sets dispatcher on node" do
      dispatch_manufactured_rjr_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_manufactured_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should == 'manufactured'
    end

    it "creates the user" do
      dispatch_manufactured_rjr_init(@d)
      Users::RJR.registry.entity(&with_id(Manufactured::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Manufactured::RJR.user
        lambda{
          dispatch_manufactured_rjr_init(@d)
        }.should_not raise_error
      end
    end

    it "adds additional privileges to user"

    it "logs in the user using the node" do
      lambda{ # XXX @d.add_module above will have already called dispatch_init
        dispatch_manufactured_rjr_init(@d)
      }.should change{Users::RJR.registry.entities.size}.by(3)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Users::Session) &&
                                       s.user.id == Manufactured::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_manufactured_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end
  end

end # module Manufactured::RJR
