# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'stringio'

describe Manufactured::Registry do

  before(:each) do
    Missions::Registry.instance.init
  end

  after(:each) do
    Missions::Registry.instance.terminate
  end

  it "provide acceses to managed missions" do
    Missions::Registry.instance.missions.size.should == 0

    mission1 = Missions::Mission.new :id => 'mission1'
    Missions::Registry.instance.create mission1

    Missions::Registry.instance.missions.size.should == 1
    Missions::Registry.instance.missions.should include(mission1)

    Missions::Registry.instance.remove mission1.id
    Missions::Registry.instance.missions.size.should == 0
  end

  it "provide acceses to managed events" do
    Missions::Registry.instance.events.size.should == 0

    event1 = Missions::Event.new :id => 'event1'
    Missions::Registry.instance.create event1

    Missions::Registry.instance.events.size.should == 1
    Missions::Registry.instance.events.should include(event1)

    Missions::Registry.instance.remove event1.id
    Missions::Registry.instance.events.size.should == 0
  end

  it "should permit global event callback to be registered for event" do
    ha = lambda { }
    hi = Missions::Registry.instance.handle_event('fooevent', &ha)

    hl = Missions::Registry.instance.handlers_for('fooevent')
    hl.keys.should include(hi)
    hl.values.should include(ha)
  end

  it "should permit specified global event callback to be removed for event" do
    ha1 = lambda { 1 }
    ha2 = lambda { 2 }

    hi1 = Missions::Registry.instance.handle_event('fooevent', &ha1)
    hi2 = Missions::Registry.instance.handle_event('fooevent', &ha2)

    Missions::Registry.instance.remove_event_handler(hi1)

    hl = Missions::Registry.instance.handlers_for('fooevent')
    hl.keys.should_not include(hi1)
    hl.values.should_not include(ha1)
    hl.keys.should include(hi2)
    hl.values.should include(ha2)
  end

  it "should permit all global event callbacks to be removed for event" do
    ha1 = lambda { }
    ha2 = lambda { }

    hi1 = Missions::Registry.instance.handle_event('fooevent', &ha1)
    hi2 = Missions::Registry.instance.handle_event('fooevent', &ha2)

    Missions::Registry.instance.remove_event_handlers('fooevent')

    hl = Missions::Registry.instance.handlers_for('fooevent')
    hl.size.should == 0
  end

  it "should run the event cycle" do
    Manufactured::Registry.instance.running?.should be_true

    called = false
    event  = Missions::Event.new :id => 'mission123', :timeout => Time.now,
                                 :callbacks => [proc{ |e|
      e.should == event
      called = true
    }]

    Missions::Registry.instance.create event
    Missions::Registry.instance.events.size.should == 1
    Missions::Registry.instance.events.should include(event)

    sleep 1
    called.should be_true
    Missions::Registry.instance.events.size.should == 0

    # ensure event ran is saved to event history list
    Missions::Registry.instance.instance_variable_get(:@event_history).should include(event)

    Missions::Registry.instance.terminate
    Missions::Registry.instance.running?.should be_false
  end

  it "should save registered missions mission and events to io object" do
    mission1 = Missions::Mission.new :id => 'mission1'
    mission2 = Missions::Mission.new :id => 'mission2'
    event1   = Missions::Event.new   :id => 'event1'
    event2   = Missions::Event.new   :id => 'event2'

    Missions::Registry.instance.create mission1
    Missions::Registry.instance.create mission2
    Missions::Registry.instance.create event1
    Missions::Registry.instance.create event2

    sio = StringIO.new
    Missions::Registry.instance.save_state(sio)
    s = sio.string

    s.should include('"id":"mission1"')
    s.should include('"id":"mission2"')
    s.should include('"id":"event1"')
    s.should include('"id":"event2"')
  end

  it "should restore registered missions entities from io object" do
    s = '{"json_class":"Missions::Mission","data":{"id":"mission1","title":"","description":"","creator_user_id":null,"assigned_to_id":null,"timeout":null,"assigned_time":null,"requirements":[],"assignment_callbacks":[],"victory_conditions":[],"victory_callbacks":[],"failure_callbacks":[]}}' + "\n" +
        '{"json_class":"Missions::Mission","data":{"id":"mission2","title":"","description":"","creator_user_id":null,"assigned_to_id":null,"timeout":null,"assigned_time":null,"requirements":[],"assignment_callbacks":[],"victory_conditions":[],"victory_callbacks":[],"failure_callbacks":[]}}' + "\n" +
        '{"json_class":"Missions::Event","data":{"id":"event1","timestamp":"2013-03-11 11:53:55 -0400","callbacks":[]}}' + "\n" +
        '{"json_class":"Missions::Event","data":{"id":"event2","timestamp":"2013-03-11 11:53:55 -0400","callbacks":[]}}' + "\n"
    a = s.split "\n"

    Missions::Registry.instance.restore_state(a)
    Missions::Registry.instance.missions.size.should == 2
    Missions::Registry.instance.events.size.should == 2

    ids = 
      (Missions::Registry.instance.missions +
       Missions::Registry.instance.events).collect { |entity|
         entity.id
      }
    ids.should include("mission1")
    ids.should include("mission2")
    ids.should include("event1")
    ids.should include("event2")
  end

end
