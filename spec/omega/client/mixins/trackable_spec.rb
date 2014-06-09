# Omega Client Trackable Mixin Tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/mixins/trackable'

module Omega::Client
  describe Trackable, :rjr => true do
    before(:each) do
      @t = OmegaTest::Trackable.new
      OmegaTest::Trackable.node.rjr_node = @n

      setup_manufactured(nil, reload_super_admin)
    end

    describe "#refresh" do
      it "refreshes the local entity from the server" do
        s1 = create(:valid_ship)
        r = OmegaTest::Trackable.get(s1.id)
        @n.should_receive(:invoke).with('manufactured::get_entity', 'with_id', s1.id)
        r.refresh
      end
    end

    describe "#method_missing" do
      it "dispatches everything to tracked entity" do
        e = double(:Object)
        e.should_receive :foobar
        @t.entity = e
        @t.foobar
      end
    end

    describe "#get_all" do
      it "returns all entities of entity_type" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        r = OmegaTest::Trackable.get_all
        r.size.should == 2
        r.all? { |ri| ri.should be_an_instance_of(OmegaTest::Trackable) }
        ids = r.collect { |s| s.id }
        ids.should include(s1.id)
        ids.should include(s2.id)
      end

      it "filters entities that fail validation" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)

        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s1.id }.and_return(false)
        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s2.id }.and_return(true)

        r = OmegaTest::Trackable.get_all
        r.size.should == 1
        r.first.id.should == s2.id
      end
    end

    describe "#get" do
      it "returns entity with specified id" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)

        r = OmegaTest::Trackable.get(s1.id)
        r.should be_an_instance_of(OmegaTest::Trackable)
        r.id.should == s1.id
      end

      context "validation fails" do
        it "returns nil" do
          s1 = create(:valid_ship)
          OmegaTest::Trackable.should_receive(:validate_entity).
                               with{|e| e.id == s1.id }.and_return(false)
          r = OmegaTest::Trackable.get(s1.id)
          r.should be_nil
        end
      end
    end

    describe "#owned_by" do
      it "returns all entities of type owned by specified user" do
        u1 = create(:user)
        u2 = create(:user)
        s1 = create(:valid_ship, :user_id => u1.id)
        s2 = create(:valid_ship, :user_id => u1.id)
        s3 = create(:valid_ship, :user_id => u2.id)

        r = OmegaTest::Trackable.owned_by(u1.id)
        r.size.should == 2
        ids = r.collect { |s| s.id }
        ids.should include(s1.id)
        ids.should include(s2.id)
      end

      it "filters entities that fail validation" do
        u1 = create(:user)
        u2 = create(:user)
        s1 = create(:valid_ship, :user_id => u1.id)
        s2 = create(:valid_ship, :user_id => u1.id)
        s3 = create(:valid_ship, :user_id => u2.id)

        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s1.id }.and_return(false)
        OmegaTest::Trackable.should_receive(:validate_entity).
                             with{|e| e.id == s2.id }.and_return(true)


        r = OmegaTest::Trackable.owned_by(u1.id)
        r.size.should == 1
        ids = r.collect { |s| s.id }
        ids.should include(s2.id)
      end
    end
  end # describe Trackable
end # module Omega::Client
