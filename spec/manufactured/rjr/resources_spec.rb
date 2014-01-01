# manufactured::add_resource,manufactured::transfer_resource tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

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

  describe "#transfer_resource", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured  :RESOURCES_METHODS

      @sys  = create(:solar_system)
      @src  = create(:valid_ship, :solar_system => @sys)
      @rsrc = @registry.safe_exec { |es| es.find &with_id(@src.id) }
      @dst  = create(:valid_ship, :solar_system => @sys)
      @rdst = @registry.safe_exec { |es| es.find &with_id(@dst.id) }

      @lt  = build(:valid_loot)
      @registry << @lt

      @rs  = build(:resource)
      @rs1 = build(:resource)
      @rsn = build(:resource)
      @rsrc.resources << @rs
      @rsrc.resources << @rs1
    end

    context "invalid src id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.transfer_resource 'invalid', @dst.id, @rs
        }.should raise_error(DataNotFound)

        lambda {
          @s.transfer_resource @lt.id, @dst.id, @rs
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid dst id/type" do
      it "raises DataNotFound" do
        lambda {
          @s.transfer_resource @src.id, 'invalid', @rs
        }.should raise_error(DataNotFound)

        lambda {
          @s.transfer_resource @src.id, @lt.id, @rs
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-src)" do
      it "raise PermissionError" do
        lambda {
          @s.transfer_resource @src.id, @dst.id, @rs
        }.should raise_error(PermissionError)
      end
    end

    context "insufficient permissions (modify-dst)" do
      it "raise PermissionError" do
        add_privilege @login_role, 'modify', "manufactured_entity-#{@src.id}"
        lambda {
          @s.transfer_resource @src.id, @dst.id, @rs
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions (modify-src && modify-dst)" do
      before(:each) do
        add_privilege @login_role, 'modify', "manufactured_entities"
      end

      it "does not raise PermissionError" do
        lambda {
          @s.transfer_resource @src.id, @dst.id, @rs
        }.should_not raise_error
      end

      it "updates src/dst locations from motel" do
        @s.node.should_receive(:invoke).
           with('motel::get_location', 'with_id', @src.id).and_call_original
        @s.node.should_receive(:invoke).
           with('motel::get_location', 'with_id', @dst.id).and_call_original
        @s.transfer_resource @src.id, @dst.id, @rs
      end

      context "resources not specified" do
        it "transfers all of src's resources" do
          @s.transfer_resource @src.id, @dst.id
          dri = @rdst.resources.collect { |r| r.id }
          dri.should include(@rs.id)
          dri.should include(@rs1.id)

          sri = @rsrc.resources.collect { |r| r.id }
          sri.should_not include(@rs.id)
          sri.should_not include(@rs1.id)
        end
      end

      context "source does not have resources" do
        it "raises ArgumentError" do
          lambda {
            @s.transfer_resource @src.id, @dst.id, @rsn
          }.should raise_error(ArgumentError)
        end
      end

      it "transfers all specified resources" do
        @s.transfer_resource @src.id, @dst.id, @rs
        dri = @rdst.resources.collect { |r| r.id }
        dri.should include(@rs.id)
        dri.should_not include(@rs1.id)

        sri = @rsrc.resources.collect { |r| r.id }
        sri.should_not include(@rs.id)
        sri.should include(@rs1.id)
      end

      context "error during resource transfer" do
        it "ensures resource allocation is reset to pre-transfer state" do
          @rdst.should_receive(:add_resource).and_call_original
          @rsrc.should_receive(:remove_resource).and_raise(Exception)
          @rdst.should_receive(:remove_resource).and_call_original

          @s.transfer_resource @src.id, @dst.id, @rs
          @rdst.resources.collect { |r| r.id }.should_not include(@rs.id)
        end
      end

      it "raises transfer event on src" do
        @rsrc.should_receive(:run_callbacks).with(:transferred_to, @rdst, @rs)
        @s.transfer_resource @src.id, @dst.id, @rs
      end

      it "raises transfer event on dst" do
        @rdst.should_receive(:run_callbacks).with(:transferred_from, @rsrc, @rs)
        @s.transfer_resource @src.id, @dst.id, @rs
      end

      it "returns [src,dst]" do
        r = @s.transfer_resource @src.id, @dst.id, @rs
        r.size.should == 2
        r.first.should be_an_instance_of(Ship)
        r.last.should be_an_instance_of(Ship)
        r.first.id.should == @src.id
        r.last.id.should == @dst.id
      end
    end

  end # describe #transfer_resource

  describe "#dispatch_manufactured_rjr_resources" do
    it "adds manufactured::add_resource to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_resources(d)
      d.handlers.keys.should include("manufactured::add_resource")
    end

    it "adds manufactured::transfer_resource to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_resources(d)
      d.handlers.keys.should include("manufactured::transfer_resource")
    end
  end
end #module Manufactured::RJR
