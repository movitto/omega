# Motel Registry Tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

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

        l2.movement_strategy = MovementStrategies::Follow.new :distance => 10,
                                                              :tracked_location_id => l1.id
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
        l3.movement_strategy = MovementStrategies::Follow.new :distance => 10,
                                                              :tracked_location_id => l1.id
        r.update(l3, &with_id(l2.id))

        r.entity(&matching{ |l| l.ms.is_a?(MovementStrategies::Follow) &&
                                l.ms.tracked_location.id == l1.id }).should_not be_nil
      end
    end

    context "changing movement strategy" do
      it "raises changed_strategy event" do
        l = build(:location)
        r = Registry.new
        l.movement_strategy = MovementStrategies::Linear.new :speed => 5
        r << l

        l1 = Location.new
        l1.update l
        l1.movement_strategy = MovementStrategies::Rotate.new

        l.should_receive(:raise_event).with(:changed_strategy).and_call_original
        r.update(l1, &with_id(l.id))
      end

      it "sets location.last_moved_at to nil" do
        l = build(:location, :last_moved_at => Time.now)
        r = Registry.new
        r << l

        l1 = Location.new
        l1.update l
        l1.movement_strategy = MovementStrategies::Linear.new
        r.update(l1, &with_id(l.id))

        r.entity(&with_id(l.id)).last_moved_at.should be_nil
      end

      it "resets tracked location attributes" do
        l = build(:location, :distance_moved => 500, :angle_rotated => 50)
        r = Registry.new
        r << l

        l1 = Location.new
        l1.update l
        l1.movement_strategy = MovementStrategies::Linear.new
        r.update(l1, &with_id(l.id))

        rl = r.entity(&with_id(l.id))
        rl.distance_moved.should == 0
        rl.angle_rotated.should == 0
      end

      context "changing to stopped" do
        it "raises stopped event" do
          l   = build(:location)
          r    = Registry.new
          l.movement_strategy = MovementStrategies::Linear.new :speed => 5
          r << l

          l1 = Location.new
          l1.update l
          l1.movement_strategy = MovementStrategies::Stopped.instance

          l.should_receive(:raise_event).with(:changed_strategy)
          l.should_receive(:raise_event).with(:stopped)
          r.update(l1, &with_id(l.id))
        end
      end
    end
  end

  it "runs location movement and event loops" do
    r = Registry.new
    r.instance_variable_get(:@event_loops).should include{ run_locations }
    r.instance_variable_get(:@event_loops).should include{ run_location_events }
  end

  describe "movement loop" do
    before(:each) do
      @r = Registry.new

      # test the loop method directly
      @run_method = proc { @r.send(:run_locations) }
      @run_events_method = proc { @r.send(:run_location_events) }
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

        @l = Location.new :step_delay => 1,
                          :movement_strategy => Motel::MovementStrategies::Linear.new
        @l.last_moved_at = @t - 2

        @r << @l
      end

      it "moves locations via movement strategy" do
        @l.ms.should_receive(:move)
        @run_method.call
      end

      it "skips stopped locations" do
        @l.ms = Motel::MovementStrategies::Stopped.instance
        @l.ms.should_not_receive(:move)
        @run_method.call
      end

      it "sets location last_moved_at" do
        @run_method.call
        @l.last_moved_at.should == @t
      end

      context "movement strategy indicates it should be changed" do
        before(:each) do
          @rl = @r.safe_exec { |es| es.find &with_id(@l.id) }
          @rl.movement_strategy.should_receive(:change?).and_return(true)

          @ms = Motel::MovementStrategies::Rotate.new
          @rl.next_movement_strategy = @ms
        end

        it "sets movement strategy to next movement strategy" do
          @r.send :run_locations
          @rl.movement_strategy.should == @ms
        end

        it "sets next movement strategy to stopped" do
          @r.send :run_locations
          @rl.next_movement_strategy.should == Motel::MovementStrategies::Stopped.instance
        end

        it "resets tracked attributes" do
          @rl.should_receive(:reset_tracked_attributes)
          @r.send :run_locations
        end

        it "invokes changed_strategy callbacks" do
          @l.should_receive(:raise_event).with(:changed_strategy)
          @l.should_receive(:raise_event).at_least(:twice)
          @r.send :run_locations
          @r.send :run_location_events
        end

        context "movement strategy changed to stopped" do
          it 'invokes stopped callbacks' do
            @l.next_movement_strategy = Motel::MovementStrategies::Stopped.instance
            @l.should_receive(:raise_event).with(:stopped)
            @l.should_receive(:raise_event).at_least(:twice)
            @r.send :run_locations
            @r.send :run_location_events
          end
        end
      end

      it "raises movement event" do
        @l.should_receive(:raise_event).with(:movement, nil, nil, nil)
        @l.should_receive(:raise_event).at_least(:once) # stub out :rotation, any others
        @run_method.call
        @run_events_method.call
      end

      it "raises rotation event" do
        @l.should_receive(:raise_event)
          .with(:rotation, nil, nil, nil)
        @l.should_receive(:raise_event).at_least(:once) # stub out :movement, other
        @run_method.call
        @run_events_method.call
      end
    end

    context "location step delay has not elapsed" do
      it "does not move location" do
        l = Location.new :step_delay => 1
        l.ms.should_not_receive(:move)
        @run_method.call
      end
    end

    it "returns smallest step_delay of non-stopped/non-moved locations" do
      t = Time.now
      l1 = build(:location, :last_moved_at => t,
                 :movement_strategy => Motel::MovementStrategies::Linear.new)
      l1.ms.step_delay = 0.5
      l2 = build(:location, :last_moved_at => t,
                 :movement_strategy => Motel::MovementStrategies::Linear.new)
      l2.ms.step_delay = 0.4
      l3 = build(:location, :last_moved_at => t)
      l3.ms.step_delay = 0.2
      @r << l1
      @r << l2
      @r << l3

      @run_method.call.should be_within(CLOSE_ENOUGH).of(0.4)
    end

    it "raises proximity events" do
      l1 = build(:location,
                  :movement_strategy => Motel::MovementStrategies::Linear.new)
      l2 = build(:location,
                  :movement_strategy => Motel::MovementStrategies::Linear.new)

      @r << l1
      @r << l2
      l1.should_receive(:raise_event).with(:proximity)
      l2.should_receive(:raise_event).with(:proximity)
      l1.should_receive(:raise_event).at_least(:once)
      l2.should_receive(:raise_event).at_least(:once)
      @run_method.call
      @run_events_method.call
    end
  end

end # describe Registry
end # module Motel
