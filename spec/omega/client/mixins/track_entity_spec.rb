# Omega Client TrackEntity Mixin tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/mixins/track_entity'

module Omega::Client
  describe TrackEntity, :rjr => true do
    before(:each) do
      OmegaTest::Trackable.node.rjr_node = @n
      setup_manufactured(nil, reload_super_admin)
    end

    after(:each) do
      OmegaTest::Trackable.clear_entities
    end

    context "entity class initialization" do
      it "initializes entity registry" do
        TrackEntity.entities.should == []
      end
    end

    context "entity initialization" do
      it "registers entity w/ local registry" do
        s = create(:valid_ship)
        t = OmegaTest::Trackable.get(s.id)
        OmegaTest::Trackable.entities.should == [t]
      end

      context "entity w/ id exists" do
        it "deletes old entity" do
          s = create(:valid_ship)
          t1 = OmegaTest::Trackable.get(s.id)
          t2 = OmegaTest::Trackable.get(s.id)
          OmegaTest::Trackable.entities.should == [t2]
        end
      end
    end

    describe "#entities" do
      it "returns entity list" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        t1 = OmegaTest::Trackable.get(s1.id)
        t2 = OmegaTest::Trackable.get(s2.id)
        OmegaTest::Trackable.entities.should == [t1, t2]
        t1.entities.should == OmegaTest::Trackable.entities
        t2.entities.should == OmegaTest::Trackable.entities
      end
    end

    describe "#clear_entities" do
      it "clears entities list" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        t1 = OmegaTest::Trackable.get(s1.id)
        t2 = OmegaTest::Trackable.get(s2.id)
        OmegaTest::Trackable.clear_entities
        OmegaTest::Trackable.entities.should == []
      end
    end

    describe "#refresh" do
      it "refreshes all entities" do
        s1 = create(:valid_ship)
        s2 = create(:valid_ship)
        t1 = OmegaTest::Trackable.get(s1.id)
        t2 = OmegaTest::Trackable.get(s2.id)
        t1.should_receive(:refresh)
        t2.should_receive(:refresh)
        OmegaTest::Trackable.refresh
      end
    end

    describe "#cached" do
      context "entity w/ id in list" do
        it "returns entity" do
          s1 = create(:valid_ship)
          t1 = OmegaTest::Trackable.get(s1.id)
          OmegaTest::Trackable.cached(s1.id).should == t1
        end
      end

      context "entity w/ id not in list" do
        it "retrieves entity w/ id" do
          s1 = create(:valid_ship)
          OmegaTest::Trackable.should_receive(:get).with(s1.id).and_return(s1)
          OmegaTest::Trackable.cached(s1.id).should == s1
        end
      end
    end

    describe "TrackEntity#entities" do
      it "returns entities from all TrackEntity subclasses" do
        sh1 = create(:valid_ship)
        st1 = create(:valid_station)
        t1 = OmegaTest::Trackable.get(sh1.id)
        t2 = OmegaTest::Trackable1.get(st1.id)
        TrackEntity.entities.should include(t1)
        TrackEntity.entities.should include(t2)
      end
    end

    describe "TrackEntity#clear_entities" do
      it "clears entities in all TrackEntity subclasses" do
        sh1 = create(:valid_ship)
        st1 = create(:valid_station)
        t1 = OmegaTest::Trackable.get(sh1.id)
        t2 = OmegaTest::Trackable1.get(st1.id)
        TrackEntity.clear_entities
        TrackEntity.entities.should == []
        OmegaTest::Trackable.entities.should == []
        OmegaTest::Trackable1.entities.should == []
      end
    end
  end
end # module Omega::Client
