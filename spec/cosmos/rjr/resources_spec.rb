# cosmos::set_resource,cosmos::get_resources tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/resources'
require 'rjr/dispatcher'

module Cosmos::RJR
  describe "#set_resource" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :RESOURCES_METHODS
      @registry = Cosmos::RJR.registry

      # XXX stub out call to motel::create_location
      Cosmos::RJR.node.stub(:invoke).and_return(build(:location))

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password).id
    end

    context "resource is not a valid resource" do
      it "raises ArgumentError" do
        lambda {
          @s.set_resource 42
        }.should raise_error(ArgumentError)

        a = build(:asteroid)
        r = build(:resource, :id => nil, :entity => a, :quantity => 10)
        lambda {
          @s.set_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "quantity is <0" do
      it "raises ArgumentError" do
        a = build(:asteroid)
        r = build(:resource, :entity => a, :quantity => -1)
        lambda {
          @s.set_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "entity not found" do
      it "raises DataNotFound" do
        r = build(:resource, :entity_id => 'foobar', :quantity => 1)
        lambda {
          @s.set_resource r
        }.should raise_error(DataNotFound)
      end
    end

    context "entity cannot accept resource" do
      it "raises ArgumentError" do
        g = create(:galaxy)
        r = build(:resource, :entity => g, :quantity => 1)
        lambda {
          @s.set_resource r
        }.should raise_error(ArgumentError)
      end
    end

    context "insufficient privileges (modify-cosmos_entities)" do
      it "raises PermissionError" do
        a = create(:asteroid)
        r = build(:resource, :entity => a, :quantity => 1)
        lambda {
          @s.set_resource r
        }.should raise_error(PermissionError)
      end
    end

    it "adds resource to entity" do
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      a = create(:asteroid)
      r = build(:resource, :entity => a, :quantity => 1)
      @s.set_resource r
      Cosmos::RJR.registry.entity(&with_id(a.id)).resources.size.should == 1
      Cosmos::RJR.registry.entity(&with_id(a.id)).resources.first.id.should == r.id
    end
 
    it "returns nil" do
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      a = create(:asteroid)
      r = build(:resource, :entity => a, :quantity => 1)
      @s.set_resource(r).should be_nil
    end
  end # describe #set_resource

  describe "#get_resource" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :RESOURCES_METHODS
      @registry = Cosmos::RJR.registry

      # XXX stub out call to motel::create_location
      Cosmos::RJR.node.stub(:invoke).and_return(build(:location))

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password).id
    end

    context "resource not found" do
      it "raises DataNotFound" do
        lambda {
          @s.get_resource 'nonexistant'
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient privileges (view-cosmos_entities)" do
      it "raises PermissionError" do
        r = create(:resource)
        lambda{
          @s.get_resource r.id
        }.should raise_error(PermissionError)
      end
    end

    it "returns entity resources" do
      add_privilege(@login_role, 'view',   'cosmos_entities')
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      r = create(:resource)

      rr = @s.get_resource(r.id)
      rr.should be_an_instance_of(Cosmos::Resource)
      rr.id.should == r.id
    end

  end # describe "#get_resource"

  describe "#get_resources" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :RESOURCES_METHODS
      @registry = Cosmos::RJR.registry

      # XXX stub out call to motel::create_location
      Cosmos::RJR.node.stub(:invoke).and_return(build(:location))

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password).id
    end

    context "entity not found" do
      it "raises DataNotFound" do
        lambda {
          @s.get_resources 'nonexistant'
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient privileges (view-cosmos_entities)" do
      it "raises PermissionError" do
        a = create(:asteroid)
        lambda{
          @s.get_resources a.id
        }.should raise_error(PermissionError)
      end
    end

    it "returns entity resources" do
      add_privilege(@login_role, 'modify', 'cosmos_entities')
      a = create(:asteroid)
      r = build(:resource, :entity => a, :quantity => 1)
      @s.set_resource(r).should be_nil

      add_privilege(@login_role, 'view', 'cosmos_entities')
      rs = @s.get_resources(a.id)
      rs.size.should == 1
      rs.first.id.should == r.id
    end
  end # describe #get_resources

  describe "#dispatch_cosmos_rjr_resources" do
    it "adds cosmos::set_resource to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_resources(d)
      d.handlers.keys.should include("cosmos::set_resource")
    end

    it "adds cosmos::get_resources to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_resources(d)
      d.handlers.keys.should include("cosmos::get_resources")
    end
  end

end #module Cosmos::RJR
