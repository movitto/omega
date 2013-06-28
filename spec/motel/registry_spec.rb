# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'timecop'

require 'motel/registry'
require 'motel/movement_strategies/linear'

module Motel
describe Registry do
  include Omega::Server::DSL

  context "adding location" do
    it "enforces unique location ids" do
      l = build(:location)
      r = Registry.new
      (r << l).should be_true
      r.entities.size.should == 1

      (r << l).should be_false
      r.entities.size.should == 1
    end

    it "sanitizes location heirarchy" do
      p   = build(:location)
      l   = build(:location)
      r   = Registry.new
      r << p

      l.parent_id = p.id
      r << l

      r.entity(&with_id(l.id)).parent_id.should == p.id
      r.entity(&matching{|l| l.parent && l.parent.id == p.id }).should_not be_nil
      r.entity(&with_id(p.id)).children.collect { |c| c.id }.should include(l.id)
    end

    context "follow movement strategy" do
      it "sets tracked_location on movement strategy" do
        p    = build(:location)
        l1   = build(:location)
        l2   = build(:location)
        r    = Registry.new
        r << p
        r << l1

        l2.movement_strategy =
          MovementStrategies::Follow.new :tracked_location_id => l1.id
        r << l2

        r.entity(&matching{|l| l.ms.is_a?(MovementStrategies::Follow) &&
                               l.ms.tracked_location.id == l1.id })
      end
    end
  end

  context "updating location" do
    it "sanitizes location heirarchy" do
      p1  = build(:location)
      p2  = build(:location)
      l   = build(:location)
      r   = Registry.new
      l.parent_id = p1.id
      r << p1
      r << p2
      r << l

      l1 = Location.new
      l1.update(l)
      l1.parent_id = p2.id
      r.update(l1, &with_id(l.id))

      r.entity(&with_id(l.id)).parent_id.should == p2.id
      r.entity(&matching{|l| l.parent && l.parent.id == p2.id }).should_not be_nil
      r.entity(&with_id(p2.id)).children.collect { |c| c.id }.should include(l.id)
      r.entity(&with_id(p1.id)).children.collect { |c| c.id }.should_not include(l.id)
    end

    context "follow movement strategy" do
      it "sets tracked_location on movement strategy" do
        l1   = build(:location)
        l2   = build(:location)
        r    = Registry.new
        r << l1
        r << l2

        l3 = Location.new
        l3.update(l2)
        l3.movement_strategy = MovementStrategies::Follow.new :tracked_location_id => l1.id
        r.update(l3, &with_id(l2.id))

        r.entity(&matching{ |l| l.ms.is_a?(MovementStrategies::Follow) &&
                                l.ms.tracked_location.id == l1.id }).should_not be_nil
      end
    end

    context "changing movement strategy" do
      context "changing to stopped" do
        it "raises stopped event" do
          l   = build(:location)
          r    = Registry.new
          l.movement_strategy = MovementStrategies::Linear.new :speed => 5
          r << l

          l1 = Location.new
          l1.update l
          l1.movement_strategy = MovementStrategies::Stopped.instance

          r.should_receive(:update).and_call_original
          r.should_receive(:raise_event).with(:updated, an_instance_of(Location), an_instance_of(Location)).and_call_original
          r.should_receive(:raise_event).with(:stopped, an_instance_of(Location))
          r.update(l1, &with_id(l.id))
        end
      end
    end
  end

  context "location event raised" do
    it "reraises event on location" do
      l = Location.new
      r = Registry.new
      r << l
      Registry::LOCATION_EVENTS.each { |e|
        l.should_receive(:raise_event).with(e, "#{e}_arg")
        r.raise_event(e, l, "#{e}_arg")
      }
    end
  end

  it "runs movement loop" do
    r = Registry.new
    r.instance_variable_get(:@event_loops).should include{ run_locations }
  end

  describe "movement loop" do
    before(:each) do
      @r = Registry.new

      # test the loop method directly
      @run_method = proc { @r.send(:run_locations) }
    end

    before(:each) do
      Timecop.freeze
    end

    after(:each) do
      Timecop.travel
    end

    after(:all) do
      Timecop.return
    end

    context "location step delay elapsed" do
      before(:each) do
        @t = Time.now

        @l = Location.new :step_delay => 1
        @l.last_moved_at = @t - 2

        @r << @l
      end

      it "moves locations via movement strategy" do
        @l.ms.should_receive(:move)
        @run_method.call
      end

      it "sets location last_moved_at" do
        @run_method.call
        @l.last_moved_at.should == @t
      end

      it "raises movement event" do
        @r.should_receive(:raise_event).with(:updated, an_instance_of(Location), an_instance_of(Location))
        @r.should_receive(:raise_event).with(:movement, an_instance_of(Location), nil, nil, nil)
        @run_method.call
      end

      it "raises rotation event" do
        @r.should_receive(:raise_event).with(:updated, an_instance_of(Location), an_instance_of(Location))
        @r.should_receive(:raise_event).with(:movement, an_instance_of(Location), nil, nil, nil)
        @r.should_receive(:raise_event).with(:rotation, an_instance_of(Location), nil, nil, nil)
        @run_method.call
      end
    end

    context "location step delay has not elapsed" do
      it "does not move location" do
        l = Location.new :step_delay => 1
        l.ms.should_not_receive(:move)
        @run_method.call
      end
    end

    it "returns smallest step_delay of non-moved locations" do # to be used as loop sleep interval
      t = Time.now
      l1 = build(:location, :last_moved_at => t)
      l1.ms.step_delay = 0.5
      l2 = build(:location, :last_moved_at => t)
      l2.ms.step_delay = 0.4
      @r << l1
      @r << l2

      @run_method.call.should be_within(CLOSE_ENOUGH).of(0.4)
    end

    it "raises proximity events" do
      @r << build(:location)
      @r << build(:location)
      @r.should_receive(:raise_event).with(:proximity, an_instance_of(Location)).twice
      @run_method.call
    end
  end

end # describe Registry
end # module Motel
