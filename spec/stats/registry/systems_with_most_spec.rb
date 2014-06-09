# systems_with_most stat tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'

describe Stats do
  describe "#systems_with_most" do
    before(:each) do
      @stat = Stats.get_stat(:systems_with_most)
      @entities = [build(:ship, :system_id => 'system2'),
                   build(:ship, :system_id => 'system1'),
                   build(:ship, :system_id => 'system2')]

      @node = Stats::RJR.node
    end

    context "invalid entity type" do
      it "should return empty array" do
        @stat.generate('invalid').value.should == []
      end
    end

    context "entities" do
      it "returns system ids sorted by number of entities in them" do
        @node.should_receive(:invoke).
              with('manufactured::get_entities', 'select', ['system_id']).
              and_return(@entities)
        @node.should_receive(:invoke).at_least(:once).and_return([])

        @stat.generate('entities').value.should == ['system2', 'system1']
      end

      it "includes ids of systems without any entities" do
        sys1 = build(:solar_system)
        sys2 = build(:solar_system)

        @node.should_receive(:invoke).
              with('manufactured::get_entities',
                   'select', ['system_id']).
              and_return([])
        @node.should_receive(:invoke).
              with('cosmos::get_entities', 'of_type',
                   'Cosmos::Entities::SolarSystem', 'children', false,
                   'select', ['id']).
              and_return([sys1, sys2])

        @stat.generate('entities').value.should == [sys1.id, sys2.id]
      end
    end

    context "num to return not specified" do
      it "returns array of all system ids" do
        @node.should_receive(:invoke).
              with('manufactured::get_entities', 'select', ['system_id']).
              and_return(@entities)
        @node.should_receive(:invoke).at_least(:once).and_return([])

        @stat.generate('entities').value.length.should == 2
      end
    end

    context "num to return specified" do
      it "returns array of first n user ids" do
        @node.should_receive(:invoke).
              with('manufactured::get_entities', 'select', ['system_id']).
              and_return(@entities)
        @node.should_receive(:invoke).at_least(:once).and_return([])

        @stat.generate('entities', 1).value.length.should == 1
      end
    end
  end
end # describe Stats
