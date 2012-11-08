# Role module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Users::Role do

  it "should properly initialize role" do
    r = Users::Role.new :id => 'role1',
                        :privileges =>
                          [Users::Privilege.new(:id => 'view', :entity_id => 'all')]
    r.id.should       == 'role1'
    r.privileges.size.should == 1
  end

  it "should permit adding and removing privileges" do
    r = Users::Role.new
    p = Users::Privilege.new
    r.privileges.size.should == 0
    r.add_privilege(p)
    r.privileges.size.should == 1
    r.privileges.first.should == p
    r.add_privilege(p)
    r.privileges.size.should == 1
  end

  it "should not permit adding duplicate privileges" do
    p1 = Users::Privilege.new :id => 'view', :entity_id => '111'
    p2 = Users::Privilege.new :id => 'view', :entity_id => '111'
    r  = Users::Role.new
    r.add_privilege(p1)
    r.add_privilege(p2)
    r.privileges.size.should == 1
  end

  it "should validate privileges" do
    p1 = Users::Privilege.new :id => 'view', :entity_id => 'entity1'
    p2 = Users::Privilege.new :id => 'modify'
    r  = Users::Role.new :privileges => [p1, p2]

    r.has_privilege_on?('view', 'entity1').should be_true
    r.has_privilege?('modify').should be_true

    r.has_privilege?('view').should be_false
    r.has_privilege_on?('view', 'entity2').should be_false
    r.has_privilege_on?('modify', 'entity1').should be_false
  end

  it "should be convertable to json" do
    role = Users::Role.new :id => 'role42',
                           :privileges => [Users::Privilege.new(:id => 'view', :entity_id => 'users')]

    j = role.to_json
    j.should include('"json_class":"Users::Role"')
    j.should include('"id":"role42"')
    j.should include('"json_class":"Users::Privilege"')
    j.should include('"id":"view"')
    j.should include('"entity_id":"users"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Users::Role","data":{"id":"role42","privileges":[{"json_class":"Users::Privilege","data":{"id":"view","entity_id":"users"}}]}}'
    r = JSON.parse(j)

    r.class.should == Users::Role
    r.id.should == "role42"
    r.privileges.size.should == 1
    r.privileges.first.id.should == 'view'
    r.privileges.first.entity_id.should == 'users'
  end

end
