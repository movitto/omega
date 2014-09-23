# universe_timestamp stat tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/registry'

describe Stats do
  describe "#universe_timestamp" do
    before(:each) do
      @stat = Stats.get_stat(:universe_timestamp)
    end

    it "returns current server time" do
      t = Time.now
      Time.stub!(:now).and_return(t)
      @stat.generate.value.should == t.to_f
    end
  end
end
