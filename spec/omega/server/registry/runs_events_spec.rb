# Omega Server Registry RunsEvents Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

require 'omega/server/event'
require 'sproc'

module Omega
module Server
module Registry
  describe RunsEvents do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
    end

    after(:each) do
      @registry.stop.join
    end

    describe "#run" do
      before(:each) do
        @ran  = 0
        @m,@c = Mutex.new,ConditionVariable.new

        @loopn = proc { @ran += 1 ; @m.synchronize { @c.signal } ; nil}
        @loop1 = proc { @ran += 1 ; @m.synchronize { @c.signal } ; 0.1}
      end

      it "adds the specified event loop to the registry" do
        # run then start
        @registry.run &@loopn
        @registry.start

        # wait and verify
        @m.synchronize { @c.wait @m, 0.1 }
        @ran.should >= 1
      end

      context "running registry" do
        it "starts event loop in new worker thread" do
          # start then run
          @registry.start
          @registry.run &@loopn

          # wait and verify
          @m.synchronize { @c.wait @m, 0.1 }
          @ran.should == 1
        end
      end

      context "event loop returns loop interval" do
        it "puts worker to sleep for interval" do
          @registry.run &@loop1
          @registry.start
          sleep 0.15
          @ran.should == 2
        end
      end

      context "event loop does not return loop interval" do
        it "puts worker to sleep for @loop_poll seconds" do
          Registry.loop_poll = 0.3
          @registry.run &@loopn
          @registry.start
          sleep 0.2
          @ran.should == 1
        end
      end
    end

    describe "#start" do
      it "starts worker threads for registered event loops" do
        m,c = Mutex.new,ConditionVariable.new
        @registry.run &(proc { m.synchronize { c.signal } ; nil })
        @registry.run &(proc { m.synchronize { c.signal } ; nil })

        @registry.start

        # wait
        m.synchronize { c.wait m, 0.1 }
        m.synchronize { c.wait m, 0.1 }

        # XXX grab handle to workers
        workers = @registry.instance_variable_get(:@workers)
        workers.size.should == 2

        @registry.should be_running
      end
    end

    describe "#stop" do
      it "terminates event loops" do
        m,c = Mutex.new,ConditionVariable.new
        @registry.run &(proc { m.synchronize { c.signal } ; nil })
        @registry.start

        m.synchronize { c.wait m, 0.1 }
        @registry.should be_running

        @registry.stop.join
        @registry.should_not be_running

        # XXX grab handle to workers
        workers = @registry.instance_variable_get(:@workers)
        workers.size.should == 0
      end
    end

    describe "#join" do
      it "joins until event loops complete" do
        m,c = Mutex.new,ConditionVariable.new
        @registry.run &(proc { m.synchronize { c.signal } ; nil })
        @registry.start
        @registry.should be_running

        @registry.stop

        # XXX grab handle to workers
        @registry.instance_variable_get(:@workers).size.should == 1

        @registry.should_not be_running

        @registry.join
        @registry.should_not be_running

        @registry.instance_variable_get(:@workers).size.should == 0
      end
    end

    describe "#running?" do
      context "start called" do
        it "returns true" do
          @registry.start
          @registry.should be_running
        end
      end

      context "stop and join called" do
        it "returns false" do
          @registry.start.stop.join
          @registry.should_not be_running
        end
      end
    end

    describe "#sanitize_event_handlers" do
      it "removes event handlers w/ duplicate event/endpoints" do
        h1 = Omega::Server::EventHandler.new :id => 'handler1',
                                             :event_type => 'registered_user',
                                             :endpoint_id => 'node1'
        h2 = Omega::Server::EventHandler.new :id => 'handler2',
                                             :event_type => 'registered_user',
                                             :endpoint_id => 'node1'
        h3 = Omega::Server::EventHandler.new :id => 'handler3',
                                             :event_type => 'registered_user',
                                             :endpoint_id => 'node2'
        @registry << h1
        @registry << h2
        @registry << h3
        @registry.entities.length.should == 3
        @registry.send :sanitize_event_handlers, h1
        @registry.entities.length.should == 2
        @registry.entities[0].id.should == 'handler1'
        @registry.entities[0].endpoint_id.should == 'node1'
        @registry.entities[1].endpoint_id.should == 'node2'
      end
    end

    describe "#run_event" do
      it "TODO: some of run_events was split out into run_event, test that here"
    end

    describe "#run_events" do
      before(:each) do
        # XXX use sprocs as handlers will be serialized
        # XXX these shouldn't be globals
        $invoked1, $invoked2, $invoked3 = false, false, false
        @h1 = SProc.new { $invoked1 = true }
        @h2 = SProc.new { $invoked2 = true }
        @h3 = SProc.new { $invoked3 = true }
      end

      it "only runs events whose time elapsed" do
        e1 = Event.new :timestamp => (Time.now - 10),
                       :handlers  => [@h1]
        e2 = Event.new :timestamp => (Time.now + 10),
                       :handlers  => [@h2]
        @registry << e1
        @registry << e2
        @registry.send :run_events
        $invoked1.should be_true
        $invoked2.should be_false
      end

      it "adds global event handlers to event" do
        e = Event.new :id => 'foobar', :type => 'et',
                      :timestamp => (Time.now - 10)
        eh1 = EventHandler.new :event_id => 'foobar', :handlers => [@h1]
        eh2 = EventHandler.new :event_id => 'barfoo', :handlers => [@h2]
        eh3 = EventHandler.new :event_type => 'et',   :handlers => [@h3]
        @registry << eh1
        @registry << eh2
        @registry << eh3
        @registry << e
        @registry.send :run_events
        $invoked1.should be_true
        $invoked2.should be_false
        $invoked3.should be_true
      end

      it "sets registry on event to self" do
        e = Event.new :timestamp => (Time.now - 10),
                      :handlers => [@h1]
        @registry << e
        re = @registry.safe_exec { |entities| entities.last }
        @registry.send :run_events
        re.registry.should == @registry
      end

      it "invokes event" do
        e = Event.new :timestamp => (Time.now - 10), :handlers => [@h1]
        @registry << e
        @registry.send :run_events
        $invoked1.should be_true
      end

      context "event raises exception" do
        it "returns gracefully" do
          h = SProc.new { raise Exception }
          e = Event.new :timestamp => (Time.now - 10), :handlers => [h]
          @registry << e
          lambda {
            @registry.send :run_events
          }.should_not raise_error
        end
      end

      it "deletes event in registry" do
        e = Event.new :id => 'eid',
                      :timestamp => (Time.now - 10),
                      :handlers => [@h1]
        @registry << e
        @registry.should_receive(:cleanup_event).
                  with { |event|
                    event.should be_an_instance_of(Event)
                    event.id.should == 'eid'
                  }
        @registry.send :run_events
      end

      it "returns default event poll" do
        e = Event.new :timestamp => (Time.now - 10)
        @registry << e
        @registry.send(:run_events).should == Registry::DEFAULT_EVENT_POLL
      end
    end

    describe "#cleanup_event" do
      before(:each) do
        @e = Event.new :id => 'eid'
        @eh1 = EventHandler.new :event_id => 'eid'
        @eh2 = EventHandler.new :event_id => 'eid'
        @eh3 = EventHandler.new :event_id => 'eid', :persist => true
        @registry << @e
        @registry << @eh1
        @registry << @eh2
        @registry << @eh3
      end

      it "removes event and handlers from registry" do
        lambda{
          @registry.send :cleanup_event, @e
        }.should change{@registry.entities.size}.by(-3)

        @registry.entities {|e|
          (e.is_a?(Event) && e.id == 'eid') ||
          (e.is_a?(EventHandler) && e.event_id == 'eid' && !e.persist)
        }.should be_empty
      end

      it "skips persistent handlers" do
        @registry.send :cleanup_event, @e
        @registry.entities {|e|
          e.is_a?(EventHandler) && e.event_id == 'eid' && e.persist
        }.size.should == 1
      end
    end
  end # describe RunsEvents
end # module Registry
end # module Server
end # module Omega
