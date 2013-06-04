# stat module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/stat'

module Stats
describe Stat do
  describe "#initialize" do
    it "sets attributes" do
      s = Stat.new :id => 'stat1', :description => 'test', :generator => :foo
      s.id.should == 'stat1'
      s.description.should == 'test'
      s.generator.should == :foo
    end
  end

  describe "#generate" do
    it "invokes generator" do
      g = proc {}
      g.should_receive(:call)
      s = Stat.new :id => 'stat1', :generator => g
      s.generate
    end

    it "passes param to generator" do
      a = nil
      g = proc { |i| a = i }
      s = Stat.new :id => 'stat1', :generator => g
      s.generate 42
      a.should == 42
    end

    it "returns new stats result" do
      g = proc {}
      s = Stat.new :id => 'stat1', :generator => g
      r = s.generate
      r.should be_an_instance_of StatResult
    end

    it "sets val on result" do
      g = proc { 42 }
      s = Stat.new :id => 'stat1', :generator => g
      r = s.generate
      r.value.should == 42
    end
  end

  describe "#to_json" do
    it "returns stat in json format" do
      s = Stats::Stat.new :id => 'stat1', :description => 'test'

      j = s.to_json
      j.should include('"json_class":"Stats::Stat"')
      j.should include('"id":"stat1"')
      j.should include('"description":"test"')
    end
  end

  describe "#json_create" do
    it "returns stat from json format" do
      j = '{"json_class":"Stats::Stat","data":{"id":"stat1","description":"test"}}'
      s = JSON.parse(j)

      s.class.should == Stats::Stat
      s.id.should == 'stat1'
      s.description.should == 'test'
    end
  end
end # describe Stat

describe StatResult do
  describe "#initialize" do
    it "sets attributes" do
      r = StatResult.new :stat_id => 'stat1', :stat => :test,
                          :args => [:fooz], :value => :foo
      r.stat_id.should == 'stat1'
      r.stat.should == :test
      r.args.should == [:fooz]
      r.value.should == :foo
    end
  end

  describe "#to_json" do
    it "returns stat result in json format" do
      s = Stat.new :id => 'stat1'
      r = StatResult.new :stat_id => s.id, :stat => s,
                                :args => ['fooz'], :value => "foo"

      j = r.to_json
      j.should include('"json_class":"Stats::StatResult"')
      j.should include('"stat_id":"stat1"')
      j.should include('"args":["fooz"]')
      j.should include('"value":"foo"')
      j.should include('"json_class":"Stats::Stat"')
      j.should include('"id":"stat1"')
    end
  end

  describe "#json_create" do
    it "returns stat result from json format" do
      j = '{"json_class":"Stats::StatResult","data":{"stat_id":"stat1","args":["fooz"],"value":"foo"}}'
      r = JSON.parse(j)

      r.class.should == Stats::StatResult
      r.stat_id.should == 'stat1'
      r.args.should == ['fooz']
      r.value.should == 'foo'
    end
  end

end # describe #StateResult
end # module Stats
