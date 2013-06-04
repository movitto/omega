# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'

describe Stats do

  it "has statistics" do
    Stats::STATISTICS.collect { |s| s.id }.should == [:num_of, :with_most, :with_least]
  end

  describe "#get_stat" do
    it "returns stat" do
      s = Stats.get_stat(:num_of)
      s.should be_an_instance_of(Stats::Stat)
      s.id.should == :num_of
    end
  end

  describe "#num_of" do
    before(:each) do
      @stat = Stats.get_stat(:num_of)
      Stats.node = double('stats-node')

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
        Stats.node.should_receive(:invoke).
                   with("users::get_entities", 'of_type', 'Users::User').
                   and_return(@entities)
        @stat.generate('users').value.should == @n
      end
    end

    context "entities" do
      it "returns number of manufactured entities" do
        Stats.node.should_receive(:invoke).
                   with("manufactured::get_entities").
                   and_return(@entities)
        @stat.generate('entities').value.should == @n
      end
    end

    context "ships" do
      it "returns number of ships" do
        Stats.node.should_receive(:invoke).
                   with("manufactured::get_entities",
                        "of_type", "Manufactured::Ship").
                        and_return(@entities)
        @stat.generate('ships').value.should == @n
      end
    end

    context "stations" do
      it "returns number of stations" do
        Stats.node.should_receive(:invoke).
                   with("manufactured::get_entities",
                        "of_type", "Manufactured::Station").
                        and_return(@entities)
        @stat.generate('stations').value.should == @n
      end
    end

    context "galaxies" do
      it "returns number of galaxies" do
        Stats.node.should_receive(:invoke).
                   with("cosmos::get_entities",
                        "of_type", "Cosmos::Galaxy").
                        and_return(@entities)
        @stat.generate('galaxies').value.should == @n
      end
    end

    context "solar_systems" do
      it "returns number of solar systems" do
        Stats.node.should_receive(:invoke).
                   with("cosmos::get_entities",
                        "of_type", "Cosmos::SolarSystem").
                        and_return(@entities)
        @stat.generate('solar_systems').value.should == @n
      end
    end

    context "planets" do
      it "returns number of planets" do
        Stats.node.should_receive(:invoke).
                   with("cosmos::get_entities",
                        "of_type", "Cosmos::Planet").
                        and_return(@entities)
        @stat.generate('planets').value.should == @n
      end
    end

    context "missions" do
      it "returns number of missions" do
        Stats.node.should_receive(:invoke).
                   with("missions::get_missions").
                        and_return(@entities)
        @stat.generate('missions').value.should == @n
      end
    end
  end # describe #num_of

  describe "#with_most" do
    before(:each) do
      @stat = Stats.get_stat(:with_most)
      Stats.node = double('stats-node')

    end

    context "invalid entity type" do
      it "should return nil" do
        @stat.generate('invalid').value.should == []
      end
    end

    context "entities" do
      it "returns user ids sorted by number of owned entities" do
        entities = [build(:ship, :user_id => 'user1'),
                     build(:ship, :user_id => 'user2'),
                     build(:station, :user_id => 'user1')]
        Stats.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(entities)
        @stat.generate('entities').value.should == ['user1', 'user2']
      end
    end

    context "kills" do
      it "returns user ids sorted by most kills" do
        #users = [build(:user, :attributes => [AttributeClass.create_attribute(Users::Attributes::ShipsUserDestroyed.id)]),
        #         build(:user),
        #         build(:user)]
      end
    end

    context "times_killed" do
      it "returns user ids sorted by most kills"
    end

    context "resources_collected" do
      it "returns user ids sorted by resources collected"
    end

    context "distance moved" do
      it "returns user ids sorted by distance moved"
    end

    context "missions completed" do
      context "returns user ids sorted by missions completed"
    end

    context "num to return not specified" do
      it "returns array of all user ids"
    end

    context "num to return specified" do
      context "num_to_return is invalid" do
        it "raises an argument error"
      end

      it "returns array of first n numer ids"
    end
  end # describe #with_most

  describe "#with_least" do
    before(:each) do
      @stat = Stats.get_stat(:with_most)
      Stats.node = double('stats-node')
    end

    context "invalid entity type" do
      it "should return nil" do
        @stat.generate('invalid').value.should == []
      end
    end

    context "times_killed" do
      it "returns user ids sorted by least times killed"
    end

    context "num to return not specified" do
      it "returns array of all user ids"
    end

    context "num to return specified" do
      context "num_to_return is invalid" do
        it "raises an argument error"
      end

      it "returns array of first n numer ids"
    end
  end # describe #with_least

  # TODO test other static stats here ...

end # describe Stats
