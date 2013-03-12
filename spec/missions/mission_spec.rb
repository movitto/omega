# Mission class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Missions::Mission do
  it "should set mission defaults" do
     mission = Missions::Mission.new
     mission.instance_variable_get(:@node).should be_nil
     mission.id.should == ""
     mission.title.should == ""
     mission.description.should == ""
     mission.creator_user_id.should be_nil
     mission.assigned_to_id.should be_nil
     mission.assigned_time.should be_nil
     mission.timeout.should be_nil
     mission.requirements.should == []
     mission.assignment_callbacks.should == []
     mission.victory_conditions.should == []
     mission.victory_callbacks.should == []
     mission.failure_callbacks.should == []
  end

  it "should successfully accept and set mission params" do
    t = Time.now
    mission = Missions::Mission.new :node => :new_node,
                                    :id   => "mission123",
                                    :title => "test_mission",
                                    :description => "test_missiond",
                                    :creator_user_id  => "user42",
                                    :assigned_to_id => "user43",
                                    :assigned_time => t,
                                    :timeout => 500,
                                    :requirements => [:req1],
                                    :assignment_callbacks => [:asi1],
                                    :victory_conditions => [:vco1],
                                    :victory_callbacks => [:vca1],
                                    :failure_callbacks => [:fc1]
    mission.instance_variable_get(:@node).should == :new_node
    mission.id.should == "mission123"
    mission.title.should == "test_mission"
    mission.description.should == "test_missiond"
    mission.creator_user_id.should == "user42"
    mission.assigned_to_id.should == "user43"
    mission.assigned_time.should == t
    mission.timeout.should == 500
    mission.requirements.should == [:req1]
    mission.assignment_callbacks.should == [:asi1]
    mission.victory_conditions.should == [:vco1]
    mission.victory_callbacks.should == [:vca1]
    mission.failure_callbacks.should == [:fc1]
  end

  it "should convert proc parameters to callable members into sprocs" do
    mission = Missions::Mission.new :requirements         => [proc { 1 + 1}],
                                    :assignment_callbacks => [proc { 2 + 2}],
                                    :victory_conditions   => [proc { 3 + 3}],
                                    :victory_callbacks    => [proc { 4 + 4}],
                                    :failure_callbacks    => [proc { 5 + 5}]

    mission.requirements.first.class.should        == SProc
    mission.assignment_callbacks.first.class.should == SProc
    mission.victory_conditions.first.class.should   == SProc
    mission.victory_callbacks.first.class.should    == SProc
    mission.failure_callbacks.first.class.should    == SProc

    mission = Missions::Mission.new :requirements => proc { 1 + 1}
    mission.requirements.class.should       == Array
    mission.requirements.size.should        == 1
    mission.requirements.first.class.should == SProc
  end

  it "should copy attributes from given mission" do
     t = Time.now
     mission1 = Missions::Mission.new :id   => "mission123", 
                                      :title => "test_mission",
                                      :description => "test_missiond",
                                      :creator_user_id  => "user42",
                                      :assigned_to_id => "user43",
                                      :assigned_time => t,
                                      :timeout => 500,
                                      :requirements => [:req1],
                                      :assignment_callbacks => [:asi1],
                                      :victory_conditions => [:vco1],
                                      :victory_callbacks => [:vca1],
                                      :failure_callbacks => [:fc1]
    mission2 = Missions::Mission.new :mission => mission1
    mission2.id.should == "mission123"
    mission2.title.should == "test_mission"
    mission2.description.should == "test_missiond"
    mission2.creator_user_id.should == "user42"
    mission2.assigned_to_id.should == "user43"
    mission2.assigned_time.should == t
    mission2.timeout.should == 500
    mission2.requirements.should == [:req1]
    mission2.assignment_callbacks.should == [:asi1]
    mission2.victory_conditions.should == [:vco1]
    mission2.victory_callbacks.should == [:vca1]
    mission2.failure_callbacks.should == [:fc1]
  end

  it "should update mission" do
     t = Time.now
     mission = Missions::Mission.new :id   => "mission123", 
                                     :title => "test_mission",
                                     :description => "test_missiond",
                                     :creator_user_id  => "user42",
                                     :assigned_to_id => "user43",
                                     :assigned_time => t,
                                     :timeout => 500,
                                     :requirements => [:req1],
                                     :assignment_callbacks => [:asi1],
                                     :victory_conditions => [:vco1],
                                     :victory_callbacks => [:vca1],
                                     :failure_callbacks => [:fc1]

     mission.update(:id   => "mission124", 
                    :title => "test_missionu",
                    :description => "test_missiondu",
                    :creator_user_id  => "user44",
                    :assigned_to_id => "user45",
                    :assigned_time => t + 500,
                    :timeout => 600,
                    :requirements => [:req2],
                    :assignment_callbacks => [:asi2],
                    :victory_conditions => [:vco2],
                    :victory_callbacks => [:vca2],
                    :failure_callbacks => [:fc2])

    mission.id.should == "mission124"
    mission.title.should == "test_missionu"
    mission.description.should == "test_missiondu"
    mission.creator_user_id.should == "user44"
    mission.assigned_to_id.should == "user45"
    mission.assigned_time.should == t + 500
    mission.timeout.should == 600
    mission.requirements.should == [:req2]
    mission.assignment_callbacks.should == [:asi2]
    mission.victory_conditions.should == [:vco2]
    mission.victory_callbacks.should == [:vca2]
    mission.failure_callbacks.should == [:fc2]
  end

  it "should clone mission" do
     t = Time.now
     mission = Missions::Mission.new :id   => "mission123", 
                                     :title => "test_mission",
                                     :description => "test_missiond",
                                     :creator_user_id  => "user42",
                                     :assigned_to_id => "user43",
                                     :assigned_time => t,
                                     :timeout => 500,
                                     :requirements => [:req1],
                                     :assignment_callbacks => [:asi1],
                                     :victory_conditions => [:vco1],
                                     :victory_callbacks => [:vca1],
                                     :failure_callbacks => [:fc1]
    mission1 = mission.clone
    mission1.id.should == "mission123"
    mission1.title.should == "test_mission"
    mission1.description.should == "test_missiond"
    mission1.creator_user_id.should == "user42"
    mission1.assigned_to_id.should == "user43"
    mission1.assigned_time.should == t
    mission1.timeout.should == 500
    mission1.requirements.should == [:req1]
    mission1.assignment_callbacks.should == [:asi1]
    mission1.victory_conditions.should == [:vco1]
    mission1.victory_callbacks.should == [:vca1]
    mission1.failure_callbacks.should == [:fc1]
  end

  it "should convert string assignment time into time" do
    t = Time.new('2013-01-01 00:00:00 -0500')
    m = Missions::Mission.new :assigned_time => t.to_s
    m.assigned_time.should == t
  end

  it "should verify validity of mission" do
    # TODO
  end

  it "should return boolean indicating if mission is assignable to user" do
     mission  = nil
     user     = Users::User.new
     node     = :node

     req1_n   = 0
     req1     = lambda { |m,u,n|
                  m.should == mission
                  u.should == user
                  n.should == node
                  req1_n += 1
                  return false
                }

     req2_n   = 0
     req2     = lambda { |m,u,n|
                  m.should == mission
                  u.should == user
                  n.should == node
                  req2_n += 1
                  return true
                }

     mission = Missions::Mission.new :node => node
     mission.assignable_to?(user).should be_true

     mission = Missions::Mission.new :node => node, :assigned_to_id => 'user42'
     mission.assignable_to?(user).should be_false

     mission = Missions::Mission.new :node => node, :requirements => [req1]
     mission.assignable_to?(user).should be_false
     req1_n.should == 1
     req2_n.should == 0

     mission = Missions::Mission.new :node => node, :requirements => [req2]
     mission.assignable_to?(user).should be_true
     req1_n.should == 1
     req2_n.should == 1

     mission = Missions::Mission.new :node => node, :requirements => [req1,req2]
     mission.assignable_to?(user).should be_false
     req1_n.should == 2
     req2_n.should == 1

     mission = Missions::Mission.new :node => node, :requirements => [req2,req2]
     mission.assignable_to?(user).should be_true
     req1_n.should == 2
     req2_n.should == 3
  end

  it "should assign mission to user" do
     user     = Users::User.new :id => 'user42'

     req1     = lambda { |m,u,n|
                  return false
                }

     mission = Missions::Mission.new :requirements => [req1]
     mission.assigned_to_id.should be_nil
     mission.assigned_to.should be_nil

     mission.assign_to(user)
     mission.assigned_to_id.should be_nil
     mission.assigned_to.should be_nil

     mission = Missions::Mission.new :node => Omega::Client::Node
     mission.assign_to(user)
     mission.assigned_to_id.should == user.id
     mission.assigned_to.should == user
  end

  it "should lookup user in registry if assigning to user id" do
     user = Users::User.new :id => 'user42'
     role = Users::Role.new :id => 'user_role_user42'
     user.add_role(role)
     Users::Registry.instance.create role
     Users::Registry.instance.create user

     mission = Missions::Mission.new :id => 'mission111', :node => Omega::Client::Node
     mission.assign_to(user)
     mission.assigned_to_id.should == user.id
     mission.assigned_to.should == user

    # ensure permission to view mission created
    user.privileges.find { |p| p.id == 'view' && p.entity_id == 'mission-mission111' }.should_not be_nil
  end

  it "should return boolean indicating if mission is expired" do
     mission = Missions::Mission.new :assigned_time => Time.now - 5, :timeout => 0
     mission.should be_expired

     mission = Missions::Mission.new :assigned_time => Time.now + 5, :timeout => 0
     mission.should_not be_expired

     mission = Missions::Mission.new :assigned_time => Time.now - 5, :timeout => 10
     mission.should_not be_expired

     # not really needed but w/e:
     mission = Missions::Mission.new :assigned_time => Time.now + 5, :timeout => 10
     mission.should_not be_expired
  end

  it "should return boolean indicating if mission is completed" do
     mission  = nil
     node     = :node

     vic1_n   = 0
     vic1     = lambda { |m,n|
                  m.should == mission
                  n.should == node
                  vic1_n += 1
                  return false
                }

     vic2_n   = 0
     vic2     = lambda { |m,n|
                  m.should == mission
                  n.should == node
                  vic2_n += 1
                  return true
                }

     mission = Missions::Mission.new :node => node, :victory_conditions => [vic1]
     mission.should_not be_completed
     vic1_n.should == 1
     vic2_n.should == 0

     mission = Missions::Mission.new :node => node, :victory_conditions => [vic2]
     mission.should be_completed
     vic1_n.should == 1
     vic2_n.should == 1

     mission = Missions::Mission.new :node => node, :victory_conditions => [vic2,vic1]
     mission.should_not be_completed
     vic1_n.should == 2
     vic2_n.should == 2

     mission = Missions::Mission.new :node => node, :victory_conditions => [vic2,vic2]
     mission.should be_completed
     vic1_n.should == 2
     vic2_n.should == 4
  end

  it "should set mission victory to true" do
     mission  = nil
     user     = Users::User.new :id => 'user42'
     node     = Omega::Client::Node

     vic1_n   = 0
     vic1     = lambda { |m,n|
                  m.should == mission
                  n.should == node
                  vic1_n += 1
                  return false
                }

     vic2_n   = 0
     vic2     = lambda { |m,n|
                  m.should == mission
                  n.should == node
                  vic2_n += 1
                  return true
                }

     mission = Missions::Mission.new :node => node, :victory_callbacks => [vic1, vic2]

     lambda{
       mission.victory!
     }.should raise_error(RuntimeError, "must be assigned")
     vic1_n.should == 0
     vic2_n.should == 0
     mission.victorious.should be_false

     mission.assign_to(user)

     mission.instance_variable_set(:@failed, true)
     lambda{
       mission.victory!
     }.should raise_error(RuntimeError, "cannot already be failed")
     vic1_n.should == 0
     vic2_n.should == 0
     mission.victorious.should be_false
     mission.instance_variable_set(:@failed, false)

     lambda{
       mission.victory!
     }.should_not raise_error
     vic1_n.should == 1
     vic2_n.should == 1
     mission.victorious.should be_true
     mission.failed.should be_false
  end

  it "should set mission failure to true" do
     mission  = nil
     user     = Users::User.new :id => 'user42'
     node     = Omega::Client::Node

     fai1_n   = 0
     fai1     = lambda { |m,n|
                  m.should == mission
                  n.should == node
                  fai1_n += 1
                  return false
                }

     fai2_n   = 0
     fai2     = lambda { |m,n|
                  m.should == mission
                  n.should == node
                  fai2_n += 1
                  return true
                }

     mission = Missions::Mission.new :node => node, :failure_callbacks => [fai1, fai2]

     lambda{
       mission.failed!
     }.should raise_error(RuntimeError, "must be assigned")
     fai1_n.should == 0
     fai2_n.should == 0
     mission.failed.should be_false

     mission.assign_to(user)

     mission.instance_variable_set(:@victorious, true)
     lambda{
       mission.failed!
     }.should raise_error(RuntimeError, "cannot already be victorious")
     fai1_n.should == 0
     fai2_n.should == 0
     mission.failed.should be_false
     mission.instance_variable_set(:@victorious, false)

     lambda{
       mission.failed!
     }.should_not raise_error
     fai1_n.should == 1
     fai2_n.should == 1
     mission.failed.should be_true
     mission.victorious.should be_false
  end

  it "should be convertable to json" do
     t = Time.now
     mission = Missions::Mission.new :node => :new_node,
                                     :id   => "mission123",
                                     :title => "test_mission",
                                     :description => "test_missiond",
                                     :creator_user_id  => "user42",
                                     :assigned_to_id => "user43",
                                     :assigned_time => t,
                                     :timeout => 500,
                                     :requirements => [:req1],
                                     :victory_conditions => [:vco1],
                                     :victory_callbacks => [:vca1],
                                     :failure_callbacks => [:fc1]
    j = mission.to_json
    j.should include('"json_class":"Missions::Mission"')
    j.should include('"id":"mission123"')
    j.should include('"title":"test_mission"')
    j.should include('"description":"test_missiond"')
    j.should include('"creator_user_id":"user42"')
    j.should include('"assigned_to_id":"user43"')
    j.should include('"assigned_time":"'+t.to_s+'"')
    j.should include('"timeout":500')
    j.should include('"requirements":["req1"]')
    j.should include('"victory_conditions":["vco1"]')
    j.should include('"victory_callbacks":["vca1"]')
    j.should include('"failure_callbacks":["fc1"]')
  end

  it "should be convertable from json" do
    t = Time.new('2013-03-10 15:33:41 -0400')
    j = '{"json_class":"Missions::Mission","data":{"id":"mission123","title":"test_mission","description":"test_missiond","creator_user_id":"user42","assigned_to_id":"user43","timeout":500,"assigned_time":"'+t.to_s+'","requirements":["req1"],"assignment_callbacks":[],"victory_conditions":["vco1"],"victory_callbacks":["vca1"],"failure_callbacks":["fc1"]}}'
    m = JSON.parse(j)

    m.class.should == Missions::Mission
    m.id.should == 'mission123'
    m.title.should == 'test_mission'
    m.description.should == 'test_missiond'
    m.creator_user_id.should == 'user42'
    m.assigned_to_id.should == 'user43'
    m.assigned_time.should == t
    m.timeout.should == 500
    m.requirements.should == ['req1']
    m.victory_conditions.should == ['vco1']
    m.victory_callbacks.should == ['vca1']
    m.failure_callbacks.should == ['fc1']
  end
end
