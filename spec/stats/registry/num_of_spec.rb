# num_of stat tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'

describe Stats do
  describe "#num_of" do
    before(:each) do
      @stat = Stats.get_stat(:num_of)

      @n = 10
      @entities = Array.new(@n)
    end

    context "other entity type" do
      it "returns nil" do
        @stat.generate('anything').value.should be_nil
      end
    end

    context "users" do
      it "returns number of users" do
        Stats::RJR.node.should_receive(:invoke).
                   with("users::get_entities", 'of_type', 'Users::User').
                   and_return(@entities)
        @stat.generate('users').value.should == @n
      end
    end

    context "entities" do
      it "returns number of manufactured entities" do
        Stats::RJR.node.should_receive(:invoke).
                   with("manufactured::get_entities").
                   and_return(@entities)
        @stat.generate('entities').value.should == @n
      end
    end

    context "ships" do
      it "returns number of ships" do
        Stats::RJR.node.should_receive(:invoke).
                   with("manufactured::get_entities",
                        "of_type", "Manufactured::Ship").
                        and_return(@entities)
        @stat.generate('ships').value.should == @n
      end
    end

    context "stations" do
      it "returns number of stations" do
        Stats::RJR.node.should_receive(:invoke).
                   with("manufactured::get_entities",
                        "of_type", "Manufactured::Station").
                        and_return(@entities)
        @stat.generate('stations').value.should == @n
      end
    end

    context "galaxies" do
      it "returns number of galaxies" do
        Stats::RJR.node.should_receive(:invoke).
                   with("cosmos::get_entities",
                        "of_type", "Cosmos::Entities::Galaxy").
                        and_return(@entities)
        @stat.generate('galaxies').value.should == @n
      end
    end

    context "solar_systems" do
      it "returns number of solar systems" do
        Stats::RJR.node.should_receive(:invoke).
                   with("cosmos::get_entities",
                        "of_type", "Cosmos::Entities::SolarSystem").
                        and_return(@entities)
        @stat.generate('solar_systems').value.should == @n
      end
    end

    context "planets" do
      it "returns number of planets" do
        Stats::RJR.node.should_receive(:invoke).
                   with("cosmos::get_entities",
                        "of_type", "Cosmos::Entities::Planet").
                        and_return(@entities)
        @stat.generate('planets').value.should == @n
      end
    end

    context "missions" do
      it "returns number of missions" do
        Stats::RJR.node.should_receive(:invoke).
                   with("missions::get_missions").
                        and_return(@entities)
        @stat.generate('missions').value.should == @n
      end
    end
  end # describe #num_of
end # describe Stats
