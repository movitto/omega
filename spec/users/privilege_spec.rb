# privilege module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Users::Privilege do

  it "should properly initialize parameters" do
    p = Users::Privilege.new :id => 'p1', :entity_id => 'e1'
    p.id.should == 'p1'
    p.entity_id.should == 'e1'
  end

  it "should be comparable against other privileges" do
    p1 = Users::Privilege.new :id => 'p1', :entity_id => 'e1'
    p1a = Users::Privilege.new :id => 'p1', :entity_id => 'e1'
    p1.should == p1a

    p2 = Users::Privilege.new :id => 'p1', :entity_id => 'e2'
    p3 = Users::Privilege.new :id => 'p2', :entity_id => 'e1'
    p4 = Users::Privilege.new :id => 'p2', :entity_id => 'e2'
    p1.should_not == p2
    p1.should_not == p3
    p1.should_not == p4
  end

  it "should be convertable to json" do
    p = Users::Privilege.new :id => 'p1', :entity_id => 'e1'

    j = p.to_json
    j.should include('"json_class":"Users::Privilege"')
    j.should include('"id":"p1"')
    j.should include('"entity_id":"e1"')
  end

  it "should be convertable from json" do
    j = '{"data":{"entity_id":"e1","id":"p1"},"json_class":"Users::Privilege"}'
    p = JSON.parse(j)

    p.class.should == Users::Privilege
    p.id.should == "p1"
    p.entity_id.should == "e1"
  end

end
