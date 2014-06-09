# universe_id stat tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'

describe Stats do
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
end # describe Stats
