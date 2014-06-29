# missions registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'stringio'

require 'spec_helper'
require 'missions/registry'

module Missions
describe Registry do
  context "adding mission" do
    context "missing creator" do
      it "retrieves creator user" do
        u = build(:user)
        m = Mission.new :id => 'foobar', :creator_id => u.id

        Missions::RJR::node.should_receive(:invoke)
                           .with('users::get_entity', 'with_id', u.id)
                           .and_return(u)

        r = Registry.new
        r << m
        r.entity { |e| e.id == m.id && e.creator.id == u.id }.should_not be_nil
      end
    end

    context "missing assigned to" do
      it "retrieves assigned to user" do
        u = build(:user)
        m = Mission.new :id => 'foobar', :assigned_to_id => u.id

        Missions::RJR::node.should_receive(:invoke).with('users::get_entity', 'with_id', u.id).and_return(u)

        r = Registry.new
        r << m
        r.entity { |e| e.id == m.id && e.assigned_to.id == u.id }.should_not be_nil
      end
    end
  end

  it "runs event loop" do
    r = Registry.new
    r.instance_variable_get(:@event_loops).should include{ run_events }
  end

  describe "#restore" do
    it "restores callbacks on restored missions" do
      # XXX block node invokations through registry callbacks
      Missions::RJR.node.should_receive(:invoke)

      m = build(:mission, :orig_callbacks => {'requirements' => ['req1']})
      r = Registry.new
      r << m


      sio = StringIO.new
      r.save(sio)
      r.clear!

      sio.rewind
      r.restore(sio)

      regm = r.entity { |e| e.id == m.id }
      regm.requirements.size.should == 1
      regm.requirements[0].should == 'req1'
    end
  end

end # describe Registry
end # module Missions
