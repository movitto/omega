# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'
require 'users/attributes/stats'

describe Stats do

  it "has statistics" do
    Stats::STATISTICS.collect { |s| s.id }.should ==
      [:universe_id, :num_of, :users_with_most, :users_with_least, :systems_with_most]
  end

  describe "#get_stat" do
    it "returns stat" do
      s = Stats.get_stat(:num_of)
      s.should be_an_instance_of(Stats::Stat)
      s.id.should == :num_of
    end
  end

  describe "#universe_id" do
    before(:each) do
      @universe_id = Stats::RJR.universe_id
      @stat = Stats.get_stat(:universe_id)
    end

    after(:each) do
      Stats::RJR.universe_id = @universe_id
    end

    it "returns universe id" do
      Stats::RJR.universe_id = 'foobar'
      @stat.generate.value.should == 'foobar'
    end
  end

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

  describe "#users_with_most" do

    before(:each) do
      @stat = Stats.get_stat(:users_with_most)

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
        Stats::RJR.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(entities)
        @stat.generate('entities').value.should == ['user1', 'user2']
      end
    end

    context "kills" do
      it "returns user ids sorted by most kills" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::ShipsUserDestroyed.create_attribute(:level => 5)]),
           build(:user, :attributes =>
             [Users::Attributes::ShipsUserDestroyed.create_attribute(:level => 10)]),
           build(:user)]
        user1, user2, user3 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').and_return(users)

        @stat.generate('kills').value.should == [user2.id, user1.id]
      end
    end

    context "times_killed" do
      it "returns user ids sorted by most kills" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 50)]),
           build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 10)]),
           build(:user, :attributes =>
             [Users::Attributes::ShipsUserDestroyed.create_attribute(:level => 20)])]
        user1, user2, user3 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('times_killed').value.should == [user1.id, user2.id]
      end
    end

    context "resources_collected" do
      it "returns user ids sorted by resources collected" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::ResourcesCollected.create_attribute(:level => 50)]),
           build(:user, :attributes =>
             [Users::Attributes::ResourcesCollected.create_attribute(:level => 60)]),
           build(:user, :attributes =>
             [Users::Attributes::ResourcesCollected.create_attribute(:level => 90)])]
        user1, user2, user3 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('resources_collected').value.should ==
          [user3.id, user2.id, user1.id]
      end
    end

    context "loot_collected" do
      it "returns user ids sorted by loot collected" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::LootCollected.create_attribute(:level => 90)]),
           build(:user, :attributes =>
             [Users::Attributes::LootCollected.create_attribute(:level => 60)]),
           build(:user, :attributes =>
             [Users::Attributes::LootCollected.create_attribute(:level => 50)])]
        user1, user2, user3 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('loot_collected').value.should ==
          [user1.id, user2.id, user3.id]
      end
    end


    context "distance moved" do
      it "returns user ids sorted by distance moved" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::DistanceTravelled.create_attribute(:level => 50)]),
           build(:user, :attributes =>
             [Users::Attributes::DistanceTravelled.create_attribute(:level => 60)]),
           build(:user, :attributes =>
             [Users::Attributes::DistanceTravelled.create_attribute(:level => 90)])]
        user1, user2, user3 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('distance_moved').value.should ==
          [user3.id, user2.id, user1.id]
      end
    end

    context "missions completed" do
      it "returns user ids sorted by missions completed" do
        user1, user2, user3, user4 =
          build(:user), build(:user), build(:user), build(:user)

        t = Time.now
        missions =
          [build(:mission, :assigned_to => user1, :assigned_time => t, :victorious => true),
           build(:mission, :assigned_to => user1, :assigned_time => t, :victorious => true),
           build(:mission, :assigned_to => user1, :assigned_time => t, :victorious => true),
           build(:mission, :assigned_to => user2, :assigned_time => t),
           build(:mission, :assigned_to => user2, :assigned_time => t, :victorious => true),
           build(:mission, :assigned_to => user2, :assigned_time => t, :victorious => true),
           build(:mission, :assigned_to => user3, :assigned_time => t, :victorious => true)]

        Stats::RJR.node.should_receive(:invoke).
                   with('missions::get_missions', 'is_active', false).
                   and_return(missions)

        @stat.generate('missions_completed').value.should ==
          [user1.id, user2.id, user3.id]
      end
    end

    context "num to return not specified" do
      it "returns array of all user ids" do
        entities = [build(:ship,    :user_id => 'user1'),
                    build(:ship,    :user_id => 'user2'),
                    build(:station, :user_id => 'user3')]
        Stats::RJR.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(entities)

        @stat.generate('entities').value.size.should == 3
      end
    end

    context "num to return specified" do
      context "num_to_return is invalid" do
        #it "raises an ArgumentError" do
        #  lambda {
        #    @stat.generate('entities', 'invalid')
        #  }.should raise_error(ArgumentError)
        #end
      end

      it "returns array of first n user ids" do
        entities = [build(:ship,    :user_id => 'user1'),
                    build(:ship,    :user_id => 'user2'),
                    build(:station, :user_id => 'user3')]
        Stats::RJR.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(entities)

        @stat.generate('entities', 2).value.size.should == 2
      end
    end
  end # describe #users_with_most

  describe "#users_with_least" do
    before(:each) do
      @stat = Stats.get_stat(:users_with_least)
    end

    context "invalid entity type" do
      it "should return nil" do
        @stat.generate('invalid').value.should == []
      end
    end

    context "times_killed" do
      it "returns user ids sorted by least times killed" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 50)]),
           build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 10)]),
           build(:user, :attributes =>
             [Users::Attributes::ShipsUserDestroyed.create_attribute(:level => 20)])]
        user1, user2, user3 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('times_killed').value.should == [user1.id, user2.id]
      end
    end

    context "num to return not specified" do
      it "returns array of all user ids" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 50)]),
           build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 10)])]
        user1,user2 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('times_killed').value.should == [user1.id, user2.id]
      end
    end

    context "num to return specified" do
      #context "num_to_return is invalid" do
      #  it "raises an argument error" do
      #  end
      #end

      it "returns array of first n user ids" do
        users =
          [build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 50)]),
           build(:user, :attributes =>
             [Users::Attributes::UserShipsDestroyed.create_attribute(:level => 10)])]
        user1,user2 = *users

        Stats::RJR.node.should_receive(:invoke).
                   with('users::get_entities').
                   and_return(users)

        @stat.generate('times_killed', 1).value.should == [user1.id]
      end
    end
  end # describe #users_with_least

  describe "#systems_with_most" do
    before(:each) do
      @stat = Stats.get_stat(:systems_with_most)
      @entities = [build(:ship, :system_id => 'system2'),
                   build(:ship, :system_id => 'system1'),
                   build(:ship, :system_id => 'system2')]
    end

    context "invalid entity type" do
      it "should return empty array" do
        @stat.generate('invalid').value.should == []
      end
    end

    context "entities" do
      it "returns system ids sorted by number of entities in them" do
        Stats::RJR.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(@entities)

        @stat.generate('entities').value.should == ['system2', 'system1']
      end
    end

    context "num to return not specified" do
      it "returns array of all system ids" do
        Stats::RJR.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(@entities)

        @stat.generate('entities').value.length.should == 2
      end
    end

    context "num to return specified" do
      it "returns array of first n user ids" do
        Stats::RJR.node.should_receive(:invoke).
                   with('manufactured::get_entities').
                   and_return(@entities)

        @stat.generate('entities', 1).value.length.should == 1
      end
    end
  end

  # TODO test other static stats here ...

end # describe Stats
