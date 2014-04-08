# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'

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
end # describe Stats
