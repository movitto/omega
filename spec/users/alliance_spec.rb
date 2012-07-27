# alliance module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Users::Alliance do

  it "should properly initialze alliance" do
    a = Users::Alliance.new :id => 'alliance1'
    a.id.should       == 'alliance1'
    a.members.size.should == 0
    a.enemies.size.should == 0
  end

  it "should permit adding an enemy" do
    e = Users::Alliance.new :id => 'a1'
    f = Users::Alliance.new :id => 'a2'
    a = Users::Alliance.new :id => 'a3'
    a.enemies.size.should == 0
    a.add_enemy(e)
    a.enemies.size.should == 1
    a.enemies.first.should == e
    a.add_enemy(e)
    a.enemies.size.should == 1
    a.add_enemy(a)
    a.enemies.size.should == 1
    a.add_enemy(1)
    a.enemies.size.should == 1
    a.add_enemy(f)
    a.enemies.size.should == 2
  end

  it "should be convertable to json" do
    user =   Users::Alliance.new :id => 'user1'
    enemy1 = Users::Alliance.new :id => 'enemy1'
    enemy2 = Users::Alliance.new :id => 'enemy2'
    alliance = Users::Alliance.new :id => 'alliance42',
                           :enemies    => [enemy1, enemy2],
                           :members    => [user]

    j = alliance.to_json
    j.should include('"json_class":"Users::Alliance"')
    j.should include('"id":"alliance42"')
    j.should include('"enemy_ids":["enemy1","enemy2"]')
    j.should include('"member_ids":["user1"]')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Users::Alliance","data":{"member_ids":["user1"],"enemy_ids":["enemy1","enemy2"],"id":"alliance42"}}'
    a = JSON.parse(j)

    a.class.should == Users::Alliance
    a.id.should == "alliance42"
  end

end
