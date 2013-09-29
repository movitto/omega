# Role module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'users/role'
require 'users/privilege'

module Users
describe Role do

  describe "#initialize" do
    it "sets attributes" do
      r = Role.new :id => 'role1',
                   :privileges =>
                     [Privilege.new(:id => 'view', :entity_id => 'all')]
      r.id.should       == 'role1'
      r.privileges.size.should == 1
    end
  end

  describe "#add_privilege" do
    it "adds privilege" do
      r = Role.new
      p = Privilege.new
      r.privileges.size.should == 0
      r.add_privilege(p)
      r.privileges.size.should == 1
      r.privileges.first.should == p
    end

    it "does not add duplicate privileges" do
      p1 = Privilege.new :id => 'view', :entity_id => '111'
      p2 = Privilege.new :id => 'view', :entity_id => '111'
      r  = Role.new
      r.add_privilege(p1)
      r.add_privilege(p2)
      r.privileges.size.should == 1
    end
  end

  describe "#remove_privilege" do
    it "removes privilege" do
      r = Users::Role.new
      p1 = Users::Privilege.new :id => 'p1'
      p2 = Users::Privilege.new :id => 'p1', :entity_id => 'e1'

      r.add_privilege(p1)
      r.add_privilege(p2)
      r.has_privilege?(p1.id).should be_true
      r.has_privilege_on?(p2.id, p2.entity_id).should be_true

      r.remove_privilege p1.id
      r.has_privilege?(p1.id).should be_false
      r.has_privilege_on?(p2.id, p2.entity_id).should be_true

      r.remove_privilege p2.id, p2.entity_id
      r.has_privilege_on?(p2.id, p2.entity_id).should be_false
    end

    context "user does not have privilege" do
      it "does nothing" do
        r = Users::Role.new
        p = Users::Privilege.new :id => 'p1'

        r.add_privilege(p)
        r.has_privilege?(p.id).should be_true

        r.remove_privilege 'p2'
        r.has_privilege?(p.id).should be_true

        r.remove_privilege p.id, 'e1'
        r.has_privilege?(p.id).should be_true
      end
    end
  end

  describe "#has_privilege_on" do
    before(:each) do
      p1 = Privilege.new :id => 'view', :entity_id => 'entity1'
      p2 = Privilege.new :id => 'modify'
      @r  = Role.new :privileges => [p1, p2]
    end

    context "has privilege" do
      it "returns true" do
        @r.has_privilege_on?('view', 'entity1').should be_true
      end
    end

    context "does not have privilege" do
      it "return false" do
        @r.has_privilege_on?('view', 'entity2').should be_false
        @r.has_privilege_on?('modify', 'entity1').should be_false
      end
    end
  end

  describe "#has_privilege" do
    before(:each) do
      p1 = Privilege.new :id => 'view', :entity_id => 'entity1'
      p2 = Privilege.new :id => 'modify'
      @r  = Role.new :privileges => [p1, p2]
    end

    context "has privilege" do
      it "returns true" do
        @r.has_privilege?('modify').should be_true
      end
    end

    context "does not have privilege" do
      it "return false" do
        @r.has_privilege?('view').should be_false
      end
    end
  end

  describe "#to_json" do
    it "should return role in json format" do
      role = Role.new :id => 'role42',
                      :privileges => [Privilege.new(:id => 'view', :entity_id => 'users')]

      j = role.to_json
      j.should include('"json_class":"Users::Role"')
      j.should include('"id":"role42"')
      j.should include('"json_class":"Users::Privilege"')
      j.should include('"id":"view"')
      j.should include('"entity_id":"users"')
    end
  end

  describe "#json_create" do
    it "should return role from json" do
      j = '{"json_class":"Users::Role","data":{"id":"role42","privileges":[{"json_class":"Users::Privilege","data":{"id":"view","entity_id":"users"}}]}}'
      r = ::RJR.parse_json(j)

      r.class.should == Users::Role
      r.id.should == "role42"
      r.privileges.size.should == 1
      r.privileges.first.id.should == 'view'
      r.privileges.first.entity_id.should == 'users'
    end
  end


end # describe Role
end # module users
