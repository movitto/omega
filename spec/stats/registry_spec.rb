# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Stats::Registry do

  before(:each) do
    Stats::Registry.instance.init
  end

  it "should get stat by id" do
    Stats::Registry.instance.get(:num_of).should_not be_nil
    Stats::Registry.instance.get(:num_of).class.should == Stats::Stat

    Stats::Registry.instance.get('num_of').should_not be_nil
    Stats::Registry.instance.get('num_of').class.should == Stats::Stat

    Stats::Registry.instance.get('fooz').should be_nil
  end

  describe "num_of" do
    it "should return the number of users" do
      s = Stats::Registry.instance.get('num_of')
      r = s.generate('users')
      r.value.should == Users::Registry.instance.find(:type => "Users::User").size
    end
  end

  describe "most_entities" do
    it "should return user ids sorted by number of entities" do
      Manufactured::Registry.instance.init

      loc1 = Motel::Location.new :id => 'loc1'
      loc2 = Motel::Location.new :id => 'loc2'
      loc3 = Motel::Location.new :id => 'loc3'
      system1 = Cosmos::SolarSystem.new :name => 'system1'
      ship1  = Manufactured::Ship.new :id => 'ship100', :user_id => 'user1', :solar_system => system1, :location => loc1
      ship2  = Manufactured::Ship.new :id => 'ship200', :user_id => 'user1', :solar_system => system1, :location => loc2
      ship3  = Manufactured::Ship.new :id => 'ship300', :user_id => 'user2', :solar_system => system1, :location => loc3
      Motel::Runner.instance.run loc1
      Motel::Runner.instance.run loc2
      Motel::Runner.instance.run loc3
      Manufactured::Registry.instance.create ship1
      Manufactured::Registry.instance.create ship2
      Manufactured::Registry.instance.create ship3

      s = Stats::Registry.instance.get('most_entities')
      r = s.generate(1)
      r.value.size.should == 1
      r.value.first.should == 'user1'

      r = s.generate(2)
      r.value.size.should == 2
      r.value.first.should == 'user1'
      r.value.last.should == 'user2'

      r = s.generate(3)
      r.value.size.should == 2
      r.value.first.should == 'user1'
      r.value.last.should == 'user2'

      r = s.generate
      r.value.size.should == 2
      r.value.first.should == 'user1'
      r.value.last.should == 'user2'
    end
  end

  # TODO test other static stats here ...
end
