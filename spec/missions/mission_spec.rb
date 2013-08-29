# Mission class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Missions
describe Mission do
  describe "#assignable_to?" do
    context "assigned to id is set" do
      it "returns false" do
        u = build(:user)
        m = Mission.new :assigned_to_id => 'foobar'
        m.should_not be_assignable_to(u)
      end
    end

    it "invokes all requirements with user" do
      u = build(:user)
      m = Mission.new :requirements => [proc { true },
                                        proc { false }]
      m.requirements.first.should_receive(:call).with(m, u)
      m.assignable_to?(u)
    end

    context "one or more requirements fails" do
      it "returns false" do
        u = build(:user)
        m = Mission.new :requirements => [proc { true },
                                          proc { false }]
        m.should_not be_assignable_to(u)
      end
    end

    context "all requirements pass" do
      it "returns true" do
        u = build(:user)
        m = Mission.new :requirements => [proc { true },
                                          proc { true }]
        m.should be_assignable_to(u)
      end
    end
  end

  describe "#assigned_to?" do
    context "assigned to user id specified" do
      it "returns true" do
        m = Mission.new :assigned_to_id => 'foobar'
        m.should be_assigned_to('foobar')
      end
    end

    context "other user id specified" do
      it "returns false" do
        m = Mission.new :assigned_to_id => 'foobar'
        m.should_not be_assigned_to('barfoo')
      end
    end

    context "assigned to user specified" do
      it "returns true" do
        u = build(:user)
        m = Mission.new :assigned_to_id => u.id
        m.should be_assigned_to(u.id)
      end
    end

    context "other user id specified" do
      it "returns false" do
        u = build(:user)
        m = Mission.new :assigned_to_id => u.id
        m.should_not be_assigned_to('barfoo')
      end
    end
  end

  context "#assigned_to=" do
    it "sets assigned_to" do
      u = Users::User.new
      m = Mission.new
      m.assigned_to = u
      m.assigned_to.should == u
    end

    it "sets assigned_to_id" do
      u = Users::User.new :id => 'u1'
      m = Mission.new
      m.assigned_to = u
      m.assigned_to_id.should == 'u1'
    end
  end

  context "#assign_to" do
    context "not assignable to user" do
      it "does not assign mission" do
        u = build(:user)
        m = Mission.new
        m.should_receive(:assigned_to?).and_return(false)
        m.assign_to(u)
        m.should_not be_assigned_to(u.id)
      end
    end

    it "sets assigned_to" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.assigned_to.should == u
    end

    it "sets assigned_to_id" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.assigned_to_id.should == u.id
    end

    it "sets assigned_time" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.assigned_time.should_not be_nil
    end
  end

  describe "#assigned?" do
    context "mission not assigned" do
      it "returns false" do
        m = Mission.new
        m.should_not be_assigned
      end
    end

    context "mission assigned" do
      it "returns true" do
        u = build(:user)
        m = Mission.new
        m.assign_to(u)
        m.should be_assigned
      end
    end
  end

  describe "#expired" do
    context "mission not assigned" do
      it "returns false" do
        m = Mission.new
        m.should_receive(:assigned?).and_return(false)
        m.should_not be_expired
      end
    end

    context "mission timeout has not yet transpired" do
      it "return false" do
        u = build(:user)
        m = Mission.new :timeout => 500
        m.assign_to(u)
        m.should_not be_expired
      end
    end

    context "mission timeout has transpired" do
      it "returns true" do
        u = build(:user)
        m = Mission.new :timeout => -500
        m.assign_to(u)
        m.should be_expired
      end
    end
  end

  describe "#clear_assignment" do
    before(:each) do
      u = build(:user)
      @m = Mission.new
      @m.assign_to(u)
      @m.clear_assignment!
    end

    it "resets assigned_to" do
      @m.assigned_to.should be_nil
    end

    it "resets assigned_to_id" do
      @m.assigned_to_id.should be_nil
    end

    it "resets assigned_time" do
      @m.assigned_time.should be_nil
    end
  end

  describe "#active?" do
    def set_state(m, assigned, expired=nil, victorious=nil, failed=nil)
      if assigned
        m.should_receive(:assigned?).and_return(true)
      else
        m.should_receive(:assigned?).and_return(false)
        return
      end

      if expired
        m.should_receive(:expired?).and_return(true)
        return
      else
        m.should_receive(:expired?).and_return(false)
      end

      if victorious
        m.victorious = true
        m.failed = false
      end

      if failed
        m.victorious = false
        m.failed = true
      end
    end

    context "mission not assigned" do
      it "returns false" do
        m = Mission.new
        set_state(m, false)
        m.should_not be_active
      end
    end

    context "mission expired" do
      it "returns false" do
        m = Mission.new
        set_state(m, true, true)
        m.should_not be_active
      end
    end

    context "mission victorious" do
      it "returns false" do
        m = Mission.new
        set_state(m, true, false, true)
        m.should_not be_active
      end
    end

    context "mission failed" do
      it "returns false" do
        m = Mission.new
        set_state(m, true, false, false, true)
        m.should_not be_active
      end
    end

    context "mission assigned, not expired, not victorious, and not failed" do
      it "returns true" do
        m = Mission.new
        set_state(m, true, false, false, false)
        m.should be_active
      end
    end
  end

  describe "#completed?" do
    context "one or more victory conditions return false" do
      it "returns false" do
        m = Mission.new :victory_conditions => [proc { true },
                                                proc { false }]
        m.victory_conditions.first.should_receive(:call).and_call_original
        m.victory_conditions.last.should_receive(:call).and_call_original
        m.should_not be_completed
      end
    end

    context "all victory conditions return true" do
      it "returns true" do
        m = Mission.new :victory_conditions => [proc { true },
                                                proc { true }]
        m.victory_conditions.first.should_receive(:call).and_call_original
        m.victory_conditions.last.should_receive(:call).and_call_original
        m.should be_completed
      end
    end
  end

  describe "#victory!" do
    context "mission not assigned" do
      it "raises RuntimeError" do
        m = Mission.new
        m.should_receive(:assigned?).and_return(false)
        lambda{
          m.victory!
        }.should raise_error(RuntimeError)
      end
    end

    context "mission failed" do
      it "raises RuntimeError" do
        u = build(:user)
        m = Mission.new
        m.assign_to(u)
        m.failed = true
        lambda{
          m.victory!
        }.should raise_error(RuntimeError)
      end
    end

    it "sets victorious true" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.victory!
      m.victorious.should be_true
    end

    it "sets failed false" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.victory!
      m.failed.should be_false
    end

    it "invokes all victory callbacks" do
      u = build(:user)
      m = Mission.new :victory_callbacks => [proc { 1 },
                                             proc { 2 }]
      m.assign_to(u)
      m.victory_callbacks.first.should_receive :call
      m.victory_callbacks.last.should_receive :call
      m.victory!
    end
  end

  describe "#failed!" do
    context "mission not assigned" do
      it "raises RuntimeError" do
        m = Mission.new
        m.should_receive(:assigned?).and_return(false)
        lambda{
          m.failed!
        }.should raise_error(RuntimeError)
      end
    end

    context "mission victorious" do
      it "raises RuntimeError" do
        u = build(:user)
        m = Mission.new
        m.assign_to(u)
        m.victorious = true
        lambda{
          m.failed!
        }.should raise_error(RuntimeError)
      end
    end

    it "sets victorious false" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.failed!
      m.victorious.should be_false
    end

    it "sets failed true" do
      u = build(:user)
      m = Mission.new
      m.assign_to(u)
      m.failed!
      m.failed.should be_true
    end

    it "invokes all failure callbacks" do
      u = build(:user)
      m = Mission.new :failure_callbacks => [proc { 1 },
                                             proc { 2 }]
      m.assign_to(u)
      m.failure_callbacks.first.should_receive :call
      m.failure_callbacks.last.should_receive :call
      m.failed!
    end
  end

  describe "#initialize" do
    it "sets attributes" do
      t = Time.now
      m = Mission.new :node => :new_node,
                      :id   => "mission123",
                      :title => "test_mission",
                      :description => "test_missiond",
                      :creator_id  => "user42",
                      :assigned_to_id => "user43",
                      :assigned_time => t,
                      :timeout => 500,
                      :requirements => [:req1],
                      :assignment_callbacks => [:asi1],
                      :victory_conditions => [:vco1],
                      :victory_callbacks => [:vca1],
                      :failure_callbacks => [:fc1],
                      :victorious        => true,
                      :failed            => true
      m.id.should == "mission123"
      m.title.should == "test_mission"
      m.description.should == "test_missiond"
      m.creator_id.should == "user42"
      m.assigned_to_id.should == "user43"
      m.assigned_time.should == t
      m.timeout.should == 500
      m.requirements.should == [:req1]
      m.assignment_callbacks.should == [:asi1]
      m.victory_conditions.should == [:vco1]
      m.victory_callbacks.should == [:vca1]
      m.failure_callbacks.should == [:fc1]
      m.victorious.should == true
      m.failed.should == true
    end

    it "sets defaults" do
      m = Mission.new
      m.id.should be_nil
      m.title.should == ""
      m.description.should == ""
      m.mission_data.should == {}
      m.creator_id.should be_nil
      m.assigned_to_id.should be_nil
      m.assigned_time.should be_nil
      m.timeout.should be_nil
      m.requirements.should == []
      m.assignment_callbacks.should == []
      m.victory_conditions.should == []
      m.victory_callbacks.should == []
      m.failure_callbacks.should == []
      m.victorious.should == false
      m.failed.should == false
    end

    it "converts time" do
      t = Time.new('2013-01-01 00:00:00 -0500')
      m = Mission.new :assigned_time => t.to_s
      m.assigned_time.should == t
    end

    [:requirements, :assignment_callbacks, :victory_conditions,
     :victory_callbacks, :failure_callbacks].each { |c|
      it "converts #{c} into an array" do
        m = Mission.new(c => proc { 1 })
        m.send(c).should be_an_instance_of(Array)
      end
    }
  end

  describe "#update" do
    it "updates mission attributes from args" do
      t = Time.now
      m = Mission.new :id   => "mission123", 
                      :title => "test_mission",
                      :description => "test_missiond",
                      :creator_id  => "user42",
                      :assigned_to_id => "user43",
                      :assigned_time => t,
                      :timeout => 500,
                      :requirements => [:req1],
                      :assignment_callbacks => [:asi1],
                      :victory_conditions => [:vco1],
                      :victory_callbacks => [:vca1],
                      :failure_callbacks => [:fc1],
                      :victorious => true,
                      :failed => true

      m.update(:id   => "mission124", 
               :title => "test_missionu",
               :description => "test_missiondu",
               :creator_id  => "user44",
               :assigned_to_id => "user45",
               :assigned_time => t + 500,
               :timeout => 600,
               :requirements => [:req2],
               :assignment_callbacks => [:asi2],
               :victory_conditions => [:vco2],
               :victory_callbacks => [:vca2],
               :failure_callbacks => [:fc2],
               :victorious => :maybe,
               :failed => :maybe)

      m.id.should == "mission124"
      m.title.should == "test_missionu"
      m.description.should == "test_missiondu"
      m.creator_id.should == "user44"
      m.assigned_to_id.should == "user45"
      m.assigned_time.should == t + 500
      m.timeout.should == 600
      m.requirements.should == [:req2]
      m.assignment_callbacks.should == [:asi2]
      m.victory_conditions.should == [:vco2]
      m.victory_callbacks.should == [:vca2]
      m.failure_callbacks.should == [:fc2]
      m.victorious.should == :maybe
      m.failed.should == :maybe
    end

    it "updates mission attributes from mission" do
      t = Time.now
      m1 = Mission.new :id   => "mission123", 
                       :title => "test_mission",
                       :description => "test_missiond",
                       :creator_id  => "user42",
                       :assigned_to_id => "user43",
                       :assigned_time => t,
                       :timeout => 500,
                       :requirements => [:req1],
                       :assignment_callbacks => [:asi1],
                       :victory_conditions => [:vco1],
                       :victory_callbacks => [:vca1],
                       :failure_callbacks => [:fc1],
                       :victorious => true,
                       :failed => true
      m2 = Mission.new
      m2.update :mission => m1
      m2.id.should == "mission123"
      m2.title.should == "test_mission"
      m2.description.should == "test_missiond"
      m2.creator_id.should == "user42"
      m2.assigned_to_id.should == "user43"
      m2.assigned_time.should == t
      m2.timeout.should == 500
      m2.requirements.should == [:req1]
      m2.assignment_callbacks.should == [:asi1]
      m2.victory_conditions.should == [:vco1]
      m2.victory_callbacks.should == [:vca1]
      m2.failure_callbacks.should == [:fc1]
      m2.victorious.should == true
      m2.failed.should == true
    end
  end

  describe "#clone" do
    it "returns copy of mission" do
      t = Time.now
      m = Mission.new :id   => "mission123", 
                      :title => "test_mission",
                      :description => "test_missiond",
                      :creator_id  => "user42",
                      :assigned_to_id => "user43",
                      :assigned_time => t,
                      :timeout => 500,
                      :requirements => [:req1],
                      :assignment_callbacks => [:asi1],
                      :victory_conditions => [:vco1],
                      :victory_callbacks => [:vca1],
                      :failure_callbacks => [:fc1],
                      :victorious => true,
                      :failed => true
      m1 = m.clone
      m1.id.should == "mission123"
      m1.title.should == "test_mission"
      m1.description.should == "test_missiond"
      m1.creator_id.should == "user42"
      m1.assigned_to_id.should == "user43"
      m1.assigned_time.should == t
      m1.timeout.should == 500
      m1.requirements.should == [:req1]
      m1.assignment_callbacks.should == [:asi1]
      m1.victory_conditions.should == [:vco1]
      m1.victory_callbacks.should == [:vca1]
      m1.failure_callbacks.should == [:fc1]
      m1.victorious.should == true
      m1.failed.should == true
    end
  end

  describe "#to_json" do
    it "returns mission in json format" do
      t = Time.now
      mission = Missions::Mission.new :id   => "mission123",
                                      :title => "test_mission",
                                      :description => "test_missiond",
                                      :creator_id  => "user42",
                                      :assigned_to_id => "user43",
                                      :assigned_time => t,
                                      :timeout => 500,
                                      :requirements => [:req1],
                                      :victory_conditions => [:vco1],
                                      :victory_callbacks => [:vca1],
                                      :failure_callbacks => [:fc1],
                                      :victorious => true,
                                      :failed => true
      j = mission.to_json
      j.should include('"json_class":"Missions::Mission"')
      j.should include('"id":"mission123"')
      j.should include('"title":"test_mission"')
      j.should include('"description":"test_missiond"')
      j.should include('"creator_id":"user42"')
      j.should include('"assigned_to_id":"user43"')
      j.should include('"assigned_time":"'+t.to_s+'"')
      j.should include('"timeout":500')
      j.should include('"requirements":["req1"]')
      j.should include('"victory_conditions":["vco1"]')
      j.should include('"victory_callbacks":["vca1"]')
      j.should include('"failure_callbacks":["fc1"]')
      j.should include('"victorious":true')
      j.should include('"failed":true')
    end
  end

  describe "#json_create" do
    it "returns mission from json format" do
      t = Time.parse('2013-03-10 15:33:41 -0400')
      j = '{"json_class":"Missions::Mission","data":{"id":"mission123","title":"test_mission","description":"test_missiond","creator_id":"user42","assigned_to_id":"user43","timeout":500,"assigned_time":"'+t.to_s+'","requirements":["req1"],"assignment_callbacks":[],"victory_conditions":["vco1"],"victory_callbacks":["vca1"],"failure_callbacks":["fc1"],"victorious":true,"failed":true}}'
      m = JSON.parse(j)

      m.class.should == Missions::Mission
      m.id.should == 'mission123'
      m.title.should == 'test_mission'
      m.description.should == 'test_missiond'
      m.creator_id.should == 'user42'
      m.assigned_to_id.should == 'user43'
      m.assigned_time.should == t
      m.timeout.should == 500
      m.requirements.should == ['req1']
      m.victory_conditions.should == ['vco1']
      m.victory_callbacks.should == ['vca1']
      m.failure_callbacks.should == ['fc1']
      m.victorious.should == true
      m.failed.should == true
    end
  end

end # describe Mission
end # module Missions
