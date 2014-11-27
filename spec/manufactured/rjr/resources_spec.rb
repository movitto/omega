# manufactured::add_resource tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/resources'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#add_resource", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured  :RESOURCES_METHODS

      @sh = create(:valid_ship)
      @rs = build(:resource)
    end

    context "not local node" do
      it "raises PermissionError" do
        @n.node_type = 'local-test'
        lambda {
          @s.add_resource 'whatever', @rs
        }.should raise_error(PermissionError)
      end
    end

    context "insufficient permissions (modify-manufactured_resources)" do
      it "raise PermissionError" do
        lambda {
          @s.add_resource 'whatever', @rs
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify-manufactured_resources)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'manufactured_resources'
      end

      it "does not raise PermissionError" do
        lambda {
          @s.add_resource @sh.id, @rs
        }.should_not raise_error
      end

      context "invalid entity id" do
        it "raises DataNotFound" do
          lambda {
            @s.add_resource 'invalid', @rs
          }.should raise_error(DataNotFound)
        end
      end

      context "invalid resource" do
        it "raises ArgumentError" do
          @rs.material_id = 'invalid'
          lambda {
            @s.add_resource @sh.id, @rs
          }.should raise_error(ArgumentError)
        end
      end

      context "invalid quantity" do
        it "raises ArgumentError" do
          @rs.quantity = 0
          lambda {
            @s.add_resource @sh.id, @rs
          }.should raise_error(ArgumentError)
        end
      end

      it "adds resource to entity in registry" do
        @s.add_resource @sh.id, @rs
        @registry.entity(&with_id(@sh.id)).resources.size.should == 1
        r = @registry.entity(&with_id(@sh.id)).resources.first
        r.id.should == @rs.id
        r.quantity.should == @rs.quantity
        r.entity_id.should == @sh.id
      end

      it "returns entity" do
        r = @s.add_resource @sh.id, @rs
        r.should be_an_instance_of(Ship)
        r.id.should == @sh.id
      end
    end
  end # describe #add_resource

  describe "#dispatch_manufactured_rjr_resources" do
    it "adds manufactured::add_resource to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_resources(d)
      d.handlers.keys.should include("manufactured::add_resource")
    end
  end
end #module Manufactured::RJR
