# Resources Event classes tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Missions::Events::Populate::Resources do
  it "should set populate resource defaults" do
    event = Missions::Events::PopulateResource.new
    event.resource.should == :random
    event.entity.should   == :random
    event.quantity.should == :random
    entity.from_entities.should  == []
    entity.from_resources.should == []
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

  it "should select random entity from list if specified" do
  end

  it "should select random resource from list if specified" do
  end

  it "should default to random quantity if not specified" do
  end

  it "should be convertable to json" do
    event = Missions::Events::PopulateResource.new

    j = event.to_json
  end

  it "should be convertable from json" do
    j = ''

    event = JSON.parse(j)
  end
end
