# Resources Event classes tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/events/resources'
require 'cosmos/entities/asteroid'
require 'cosmos/resource'

module Missions
module Events
describe PopulateResource do
  describe "#handle_event" do
    before(:each) do
      @a = Cosmos::Entities::Asteroid.new :id => 'ast'
      @r = Cosmos::Resource.new :type => 'metal', :name => 'steel'
      @e = PopulateResource.new :entity => @a, :resource => @r, :quantity => 50
    end

    context "resource == :random" do
      it "picks random resource" do
        Missions::RJR.node.should_receive(:invoke) # stub out invoke

        @e.resource = :random

        rs = [1,2,3]
        @e.stub!(:rand).with(3).and_return(1)
        rs.should_receive(:[]).with(1).and_return(@r)
        @e.from_resources = rs

        @e.send :handle_event
        @e.resource.should == @r
      end
    end

    context "entity == :random" do
      it "picks random entity" do
        Missions::RJR.node.should_receive(:invoke) # stub out invoke

        @e.entity = :random

        as = [1,2,3]
        @e.stub!(:rand).with(3).and_return(1)
        as.should_receive(:[]).with(1).and_return(@a)
        @e.from_entities = as

        @e.send :handle_event
        @e.entity.should == @a
        @e.resource.entity_id.should == @a.id
      end
    end

    context "quantity == :random" do
      it "picks random quantity" do
        Missions::RJR.node.should_receive(:invoke) # stub out invoke

        @e.quantity = :random
        @e.stub!(:rand).
               with(PopulateResource::DEFAULT_QUANTITY).
               and_return(42)

        @e.send :handle_event
        @e.quantity.should == 42
        @e.resource.quantity.should == 42
      end
    end

    it "sets resources" do
      Missions::RJR.node.should_receive(:invoke).
                         with { |m,r|
                           m.should == 'cosmos::set_resource'
                           r.should be_an_instance_of(Cosmos::Resource)
                           r.id.should_not be_nil
                           r.entity_id.should == @a.id
                           r.material_id.should == @r.material_id
                           r.quantity.should == 50
                         }
      @e.send :handle_event
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      event = PopulateResource.new
      event.resource.should == :random
      event.entity.should   == :random
      event.quantity.should == :random
      event.from_entities.should  == []
      event.from_resources.should == []
    end

    it "sets attributes" do
      event = PopulateResource.new :resource => 'resource1',
                                   :entity => 'entity1',
                                   :quantity => 500,
                                   :from_entities => ['ent2'],
                                   :from_resources => ['res2']
      event.resource.should == 'resource1'
      event.entity.should   == 'entity1'
      event.quantity.should ==  500
      event.from_entities.should  == ['ent2']
      event.from_resources.should == ['res2']
    end

    it "adds handler to handle_event" do
      event = PopulateResource.new
      event.handlers.size.should == 1
      event.should_receive(:handle_event)
      event.invoke
    end
  end

  describe "#to_json" do
    it "returns event in json format" do
    t = Time.now
    event = PopulateResource.new :id => 'pre123', :timestamp => t,
                                 :handlers => [:cb1],
                                 :resource  => :res1,
                                 :entity    => :random,
                                 :quantity  =>   123,
                                 :from_entities  => [:ent2, :ent3],
                                 :from_resources => [:res2, :res3]

    j = event.to_json
    j.should include('"json_class":"Missions::Events::PopulateResource"')
    j.should include('"id":"pre123"')
    j.should include('"timestamp":"'+t.to_s+'"')
    j.should include('"handlers":["cb1"]')
    j.should include('"resource":"res1"')
    j.should include('"entity":"random"')
    j.should include('"quantity":123')
    j.should include('"from_entities":["ent2","ent3"]')
    j.should include('"from_resources":["res2","res3"]')
    end
  end

  describe "#json_create" do
    it "returns event from json format" do
    t = Time.parse('2013-03-10 15:33:41 -0400')
    j = '{"json_class":"Missions::Events::PopulateResource","data":{"id":"pre123","timestamp":"2013-03-10 15:33:41 -0400","handlers":["cb1"],"resource":"res1","entity":"random","quantity":123,"from_entities":["ent2","ent3"],"from_resources":["res2","res3"]}}'

    event = ::RJR.parse_json(j)
    event.class.should == Missions::Events::PopulateResource
    event.id.should == 'pre123'
    event.timestamp.should == t
    event.handlers.size.should == 2
    event.handlers.last.should == 'cb1'
    event.resource.should == 'res1'
    event.entity.should == :random
    event.quantity.should == 123
    event.from_entities.should  == ['ent2', 'ent3']
    event.from_resources.should == ['res2', 'res3']
    end
  end

end # describe PopulateResource
end # module Events
end # module Missions
