# Resources Event classes tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Missions::Events::PopulateResource do
  it "should set populate resource defaults" do
    event = Missions::Events::PopulateResource.new
    event.resource.should == :random
    event.entity.should   == :random
    event.quantity.should == :random
    event.from_entities.should  == []
    event.from_resources.should == []
  end

  it "should accept populate resource event args" do
    event = Missions::Events::PopulateResource.new :resource => 'resource1', :entity => 'entity1',
                                                   :quantity => 500,
                                                   :from_entities => ['ent2'], :from_resources => ['res2']
    event.resource.should == 'resource1'
    event.entity.should   == 'entity1'
    event.quantity.should ==  500
    event.from_entities.should  == ['ent2']
    event.from_resources.should == ['res2']
  end

  it "should run callback to invoke cosmos::set_resource" do
    event = Missions::Events::PopulateResource.new
    event.callbacks.size.should == 1
  end

  it "should select random entity,resource,quantity" do
    # TODO
  end

  it "should be convertable to json" do
    t = Time.now
    event = Missions::Events::PopulateResource.new :id => 'pre123', :timestamp => t,
                                                   :callbacks => [:cb1],
                                                   :resource  => :res1,
                                                   :entity    => :random,
                                                   :quantity  =>   123,
                                                   :from_entities  => [:ent2, :ent3],
                                                   :from_resources => [:res2, :res3]

    j = event.to_json
    j.should include('"json_class":"Missions::Events::PopulateResource"')
    j.should include('"id":"pre123"')
    j.should include('"timestamp":"'+t.to_s+'"')
    j.should include('"callbacks":["cb1"]')
    j.should include('"resource":"res1"')
    j.should include('"entity":"random"')
    j.should include('"quantity":123')
    j.should include('"from_entities":["ent2","ent3"]')
    j.should include('"from_resources":["res2","res3"]')
  end

  it "should be convertable from json" do
    t = Time.new('2013-03-10 15:33:41 -0400')
    j = '{"json_class":"Missions::Events::PopulateResource","data":{"id":"pre123","timestamp":"2013-03-10 15:50:16 -0400","callbacks":["cb1"],"resource":"res1","entity":"random","quantity":123,"from_entities":["ent2","ent3"],"from_resources":["res2","res3"]}}'

    event = JSON.parse(j)
    event.class.should == Missions::Events::PopulateResource
    event.id.should == 'pre123'
    event.timestamp.should == t
    event.callbacks.size.should == 2
    event.callbacks.last.should == 'cb1'
    event.resource.should == 'res1'
    event.entity.should == :random
    event.quantity.should == 123
    event.from_entities.should  == ['ent2', 'ent3']
    event.from_resources.should == ['res2', 'res3']
  end
end
