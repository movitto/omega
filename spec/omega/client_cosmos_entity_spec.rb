# client cosmos_entity module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Omega::Client::Galaxy do
  it "should be remotely trackable" do
    gal1  = FactoryGirl.build(:gal1)
    g = Omega::Client::Galaxy.get(gal1.name)
    g.id.should == gal1.name
  end
end

describe Omega::Client::SolarSystem do
  it "should be remotely trackable" do
    sys1  = FactoryGirl.build(:sys1)

    s = Omega::Client::SolarSystem.get('sys1')
    s.id.should == 'sys1'
  end

  it "should return system with the fewest stations" do
    stat1 = FactoryGirl.build(:station1)
    stat2 = FactoryGirl.build(:station2)
    stat3 = FactoryGirl.build(:station3)

    sys = Omega::Client::SolarSystem.with_fewest "Manufactured::Station"
    sys.should_not be_nil
    sys.id.should == 'sys2'
  end
end
