# resource module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Cosmos::Resource do

  it "should successfully accept and set resource params" do
     resource   = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
     resource.name.should == 'titanium'
     resource.type.should == 'metal'
     resource.id.should == "metal-titanium"
  end

  it "should verify validity of resource" do
     resource   = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
     resource.valid?.should be_true

     resource.name = 11111
     resource.valid?.should be_false

     resource.name = nil
     resource.valid?.should be_false
     resource.name = 'titanium'

     resource.type = nil
     resource.valid?.should be_false
  end

  it "should successfully accept resource to copy" do
     resource1   = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
     resource2   = Cosmos::Resource.new :resource => resource1
     resource2.name.should == 'titanium'
     resource2.type.should == 'metal'
     resource2.id.should == "metal-titanium"
  end

  it "should be convertable to json" do
    r = Cosmos::Resource.new :name => 'titanium', :type => 'metal'

    j = r.to_json
    j.should include('"json_class":"Cosmos::Resource"')
    j.should include('"id":"'+r.id+'"')
    j.should include('"name":"titanium"')
    j.should include('"type":"metal"')
  end

  it "should be convertable from json" do
    j = '{"data":{"type":"metal","name":"titanium"},"json_class":"Cosmos::Resource"}'
    r = JSON.parse(j)

    r.class.should == Cosmos::Resource
    r.name.should == 'titanium'
    r.type.should == 'metal'
  end

end

describe Cosmos::ResourceSource do

  it "should successfully accept and set resource source params" do
     a = Cosmos::Asteroid.new :name => 'asteroid1'
     r = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
     rs = Cosmos::ResourceSource.new :id => 'foosource', :resource => r, :quantity => 50, :entity => a

     rs.resource.should == r
     rs.id.should == 'foosource'
     rs.entity.should == a
     rs.quantity.should == 50
  end

  it "should automatically generate a uuid id if not specified" do
    rs = Cosmos::ResourceSource.new
    rs.id.should_not be_nil
    rs.id.should =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/
  end

  it "should be convertable to json" do
     a = Cosmos::Asteroid.new :name => 'asteroid1'
     r = Cosmos::Resource.new :name => 'titanium', :type => 'metal'
     rs = Cosmos::ResourceSource.new :id => 'fooz', :resource => r, :quantity => 50, :entity => a

    j = rs.to_json
    j.should include('"json_class":"Cosmos::ResourceSource"')
    j.should include('"id":"fooz"')
    j.should include('"quantity":50')
    j.should include('"json_class":"Cosmos::Resource"')
    j.should include('"name":"titanium"')
    j.should include('"type":"metal"')
    j.should include('"json_class":"Cosmos::Asteroid"')
    j.should include('"name":"asteroid1"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Cosmos::ResourceSource","data":{"entity":{"json_class":"Cosmos::Asteroid","data":{"color":"0a6613","size":10,"name":"asteroid1","location":{"json_class":"Motel::Location","data":{"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"y":0,"parent_id":null,"z":0,"restrict_view":true,"x":0,"restrict_modify":true,"id":null,"remote_queue":null}}}},"resource":{"json_class":"Cosmos::Resource","data":{"type":"metal","name":"titanium"}},"quantity":50,"id":"fooz"}}'
    r = JSON.parse(j)

    r.class.should == Cosmos::ResourceSource
    r.id.should == "fooz"
    r.quantity.should == 50
    r.resource.class.should == Cosmos::Resource
    r.resource.name.should == "titanium"
    r.resource.type.should == "metal"
    r.entity.class.should == Cosmos::Asteroid
    r.entity.name.should  == "asteroid1"
  end

end
