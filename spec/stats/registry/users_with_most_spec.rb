# users_with_most stat tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'
require 'users/attributes/stats'

describe Stats do
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
end # describe Stats
