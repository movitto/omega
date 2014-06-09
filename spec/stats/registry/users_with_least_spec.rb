# users_with_least stat tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'
require 'users/attributes/stats'

describe Stats do
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

end # describe Stats
