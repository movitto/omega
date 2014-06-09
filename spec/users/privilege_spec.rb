# privilege module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/common'

module Users
describe Privilege do

  describe "#initialize" do
    it "set attributes" do
      p = Privilege.new :id => 'p1', :entity_id => 'e1'
      p.id.should == 'p1'
      p.entity_id.should == 'e1'
    end
  end

  describe "#==" do
    it "compares privilegs" do
      p1  = Privilege.new :id => 'p1', :entity_id => 'e1'
      p1a = Privilege.new :id => 'p1', :entity_id => 'e1'
      p1.should == p1a

      p2 = Privilege.new :id => 'p1', :entity_id => 'e2'
      p3 = Privilege.new :id => 'p2', :entity_id => 'e1'
      p4 = Privilege.new :id => 'p2', :entity_id => 'e2'
      p1.should_not == p2
      p1.should_not == p3
      p1.should_not == p4
    end
  end

  describe "#to_json" do
    it "should return json representation" do
      p = Privilege.new :id => 'p1', :entity_id => 'e1'

      j = p.to_json
      j.should include('"json_class":"Users::Privilege"')
      j.should include('"id":"p1"')
      j.should include('"entity_id":"e1"')
    end
  end

  describe "#json_create" do
    it "should return privilege from json" do
      j = '{"data":{"entity_id":"e1","id":"p1"},"json_class":"Users::Privilege"}'
      p = ::RJR::JSONParser.parse(j)

      p.class.should == Users::Privilege
      p.id.should == "p1"
      p.entity_id.should == "e1"
    end
  end

end # describe Privilege
end # modue Users
