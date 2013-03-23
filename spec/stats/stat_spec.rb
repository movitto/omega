# stat module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Stats::Stat do

  it "should successfully accept and set stat params" do
    s = Stats::Stat.new :id => 'stat1', :description => 'test', :generator => :foo
    s.id.should == 'stat1'
    s.description.should == 'test'
    s.generator.should == :foo
  end

  it "should generate stat result" do
    s = Stats::Stat.new :id => 'stat1', :generator => proc { |i| i.should == 5 ; 6 }
    r = s.generate 5
    r.stat_id.should == s.id
    r.stat.should == s
    r.args.should == [5]
    r.value.should == 6
  end

  it "should be convertable to json" do
    s = Stats::Stat.new :id => 'stat1', :description => 'test'

    j = s.to_json
    j.should include('"json_class":"Stats::Stat"')
    j.should include('"id":"stat1"')
    j.should include('"description":"test"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Stats::Stat","data":{"id":"stat1","description":"test"}}'
    s = JSON.parse(j)

    s.class.should == Stats::Stat
    s.id.should == 'stat1'
    s.description.should == 'test'
  end
end

describe Stats::StatResult do
  it "should successfully accept and set stat result params" do
    r = Stats::StatResult.new :stat_id => 'stat1', :stat => :test,
                              :args => [:fooz], :value => :foo
    r.stat_id.should == 'stat1'
    r.stat.should == :test
    r.args.should == [:fooz]
    r.value.should == :foo
  end

  it "should be convertable to json" do
    s = Stats::Stat.new :id => 'stat1'
    r = Stats::StatResult.new :stat_id => s.id, :stat => s,
                              :args => ['fooz'], :value => "foo"

    j = r.to_json
    j.should include('"json_class":"Stats::StatResult"')
    j.should include('"stat_id":"stat1"')
    j.should include('"args":["fooz"]')
    j.should include('"value":"foo"')
    j.should include('"json_class":"Stats::Stat"')
    j.should include('"id":"stat1"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Stats::StatResult","data":{"stat_id":"stat1","args":["fooz"],"value":"foo"}}'
    r = JSON.parse(j)

    r.class.should == Stats::StatResult
    r.stat_id.should == 'stat1'
    r.args.should == ['fooz']
    r.value.should == 'foo'
  end
end
