# Omega Server Registry tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'stringio'
require 'ostruct'

require 'spec_helper'

require 'rjr/common' # for eigenclass
require 'omega/server/registry'
require 'omega/server/event'
require 'sproc'

module Omega
module Server

describe Registry do
  before(:each) do
    @registry = Object.new
    @registry.extend(Registry)
  end

  after(:each) do
    @registry.stop.join
  end

  describe "#entities" do
    it "returns all entities" do
      @registry << 1
      @registry << 2
      @registry.entities.should == [1, 2]
    end

    it "returns entities matching criteria" do
      @registry << 5
      @registry << 10
      @registry.entities { |e| e > 6 }.should == [10]
    end

    it "returns the copies of entities" do
      obj = { 'foo' => 'bar' }
      @registry << obj
      e = @registry.entities

      # test values are same but objects are not
      e.first.should == obj
      e.first.should_not equal(obj)
    end

    it "invokes retrieval on each entity" do
      @registry << OpenStruct.new(:id => 21)
      @registry << OpenStruct.new(:id => 42)
      e1 = @registry.safe_exec { |es| es.find { |i| i.id == 21 }}
      e2 = @registry.safe_exec { |es| es.find { |i| i.id == 42 }}

      @registry.retrieval.should_receive(:call).with(e1)
      @registry.retrieval.should_receive(:call).with(e2)
      e = @registry.entities
    end
  end

  describe "#entity" do
    it "returns first matching result" do
      @registry << 1
      @registry << 2
      @registry << 3
      selector = proc { |e| e % 2 != 0 }
      v = @registry.entity &selector
      v.should == 1
    end
  end

  describe "#clear!" do
    it "empties entities list" do
      @registry << 1
      @registry << 2
      @registry.clear!
      @registry.entities.should be_empty
    end
  end

  describe "#<<" do
    before(:each) do
      @added = nil
      @registry.on(:added) { |e| @added = e }
    end

    context "validation not set" do
      it "adds entity" do
        @registry << 1
        @registry << 1
        @registry.entities.should == [1, 1]
      end

      it "returns true" do
        @registry.<<(1).should be_true
        @registry.<<(1).should be_true
      end

      it "raises added event" do
        @registry << 1
        @added.should == 1

        @registry << 2
        @added.should == 2

        @registry << 1
        @added.should == 1
      end
    end

    context "validation is set" do
      before(:each) do
        @registry.validation_callback { |entities, e|
          !entities.include?(e)
        }
      end

      context "validation passes" do
        it "adds entity" do
          @registry << 1
          @registry << 2
          @registry.entities.should == [1,2]
        end

        it "returns true" do
          @registry.<<(1).should be_true
          @registry.<<(2).should be_true
        end

        it "raises added event" do
          @registry << 1
          @added.should == 1

          @registry << 2
          @added.should == 2
        end
      end

      context "validation fails" do
        it "doesn't add the entity" do
          @registry << 1
          @registry << 1
          @registry.entities.should == [1]
        end

        it "returns false" do
          @registry.<<(1).should be_true
          @registry.<<(1).should be_false
        end

        it "doesn't raise added event" do
          @registry << 1
          @added.should == 1

          @registry << 2
          @added.should == 2

          @registry << 1
          @added.should == 2
        end
      end
    end

    context "multiple validations are set" do
      before(:each) do
        @first = true
        @second = true
        @registry.validation_callback { |entities, e|
          @first
        }
        @registry.validation_callback { |entities, e|
          @second
        }
      end

      context "all validations passes" do
        it "adds entity" do
          @registry << 1
          @registry.entities.should == [1]
        end

        it "returns true" do
          @registry.<<(1).should be_true
        end

        it "raises added event" do
          @registry << 1
          @added.should == 1
        end
      end

      context "one or more validations fail" do
        before(:each) do
          @second = false
        end

        it "doesn't add the entity" do
          @registry << 1
          @registry.entities.should == []
        end

        it "returns false" do
          @registry.<<(1).should be_false
        end

        it "doesn't raise added event" do
          @registry << 1
          @added.should be_nil
        end
      end
    end
  end

  describe "#delete" do
    it "deletes first entity matching selector" do
      @registry << 1
      @registry << 2
      @registry << 3
      @registry.delete { |e| e % 2 != 0 }
      @registry.entities.should_not include(1)
      @registry.entities.should include(2)
      @registry.entities.should include(3)
    end

    context "entity deleted" do
      it "raises :deleted event" do
        @registry << 1
        @registry.should_receive(:raise_event).with(:deleted, 1)
        @registry.delete
      end

      it "returns true" do
        @registry << 1
        @registry.delete.should be_true
      end
    end

    context "entity not deleted" do
      it "does not raise :deleted event" do
        @registry.should_not_receive(:raise_event)
        @registry.delete { |e| false }
      end

      it "returns false" do
        @registry.delete { |e| false }.should be_false
      end
    end
  end

  describe "#update" do
    before(:each) do
      # primary entities (first two will be stored)
      @e1  = OmegaTest::ServerEntity.new(:id => 1, :val => 'a')
      @e2  = OmegaTest::ServerEntity.new(:id => 2, :val => 'b')
      @e3  = OmegaTest::ServerEntity.new(:id => 3, :val => 'c')

      # create an copy of e2/e3 which we will not modify (for validation)
      @orig_e2  = OmegaTest::ServerEntity.new(:id => 2, :val => 'b')
      @orig_e3  = OmegaTest::ServerEntity.new(:id => 3, :val => 'c')

      # create entities to use to update
      @e2a = OmegaTest::ServerEntity.new(:id => 2, :val => 'd')
      @e3a = OmegaTest::ServerEntity.new(:id => 3, :val => 'e')

      # define a selector which to use to select entities
      @select_e2 = proc { |e| e.id == @e2.id }
      @select_e3 = proc { |e| e.id == @e3.id }

      # update requires 'update' method on entities
      [@e1, @e2, @e3].each { |e|
        e.eigenclass.send(:define_method, :update,
                    proc { |v| self.val = v.val })
      }

      # add entities to registry
      @registry << @e1
      @registry << @e2

      # handle updated event
      @updated_n = @updated_o = nil
      @registry.on(:updated) { |n,o| @updated_n = n ; @updated_o = o }
    end

    context "selected entity found" do
      it "updates entity" do
        @registry.update(@e2a, &@select_e2) 
        @e2.should == @e2a
      end

      it "raises updated event" do
        @registry.update(@e2a, &@select_e2)
        @updated_n.should == @e2a
        @updated_o.should == @orig_e2
      end

      it "returns true" do
        @registry.update(@e2a, &@select_e2).should == true
      end
    end

    context "selected entity not found" do
      it "does not update entity" do
        @registry.update(@e3a, &@select_e3) 
        @e3.should == @orig_e3
      end

      it "does not raise updated event" do
        @registry.update(@e3a, &@select_e3)
        @updated_n.should be_nil
        @updated_o.should be_nil
      end

      it "returns false" do
        @registry.update(@e3a, &@select_e3).should be_false
      end
    end
  end

  describe "#proxies_for" do
    it "returns proxy entities for entities retrieved by the specified selector" do
      e1 = Object.new
      e2 = Object.new
      @registry << e1
      @registry << e2
      e1.stub(:to_json).and_return('{}')
      e2.stub(:to_json).and_return('{}')
      p = @registry.proxies_for { |e| true }
      p.should be_an_instance_of(Array)
      p.size.should == 2
      p.should == [e1, e2]
    end
  end

  describe "#proxy_for" do
    it "returns proxy entity for entity retrieved by the specified selector" do
      e1 = Object.new
      e2 = Object.new
      @registry << e1
      @registry << e2
      e1.stub(:to_json).and_return('{}')
      e2.stub(:to_json).and_return('{}')
      p = @registry.proxy_for { |e| true }
      #p.should be_an_instance_of(ProxyEntity) # TODO
      p.should == e1
    end

    context "entity not found" do
      it "returns null" do
        p = @registry.proxy_for { |e| e == 1 }
        p.should be_nil
      end
    end

    it "sets registry on proxy entity" do
        e = Object.new
        e.stub(:to_json).and_return('{}')
        e.stub(:foobar) {
          lambda{
            @registry.safe_exec {}
          }.should raise_error(ThreadError)
        }
        @registry << e
        p = @registry.proxy_for { |e| true }
        p.foobar
    end
  end

  describe "#safe_exec" do
    it "safely executes a block of code" do
      @registry.safe_exec { |entities|
        proc {
          @registry.safe_exec
        }.should raise_error(ThreadError, "deadlock; recursive locking")
      }
    end

    it "passes entities array to block" do
      eids1 = @registry.entities.collect { |e| e.id }
      eids2 = @registry.safe_exec { |entities|
                entities.collect { |e| e.id } }
      eids1.should == eids2
    end
  end

  describe "#on" do
    it "registers a handler to an event" do
      ran = nil
      @registry.on(:foobar) { |p| ran = p }
      @registry.raise_event :foobar, :barfoo
      ran.should == :barfoo
    end

    it "registers a handler to multiple events" do
      ran = nil
      @registry.on([:foobar, :test]) { |p| ran = p }
      @registry.raise_event :foobar, :barfoo
      ran.should == :barfoo

      ran = nil
      @registry.raise_event :test, :hi
      ran.should == :hi
    end
  end

  describe "#raise_event" do
    it "invokes the handlers for the specified event" do
      ran = nil
      @registry.on(:foobar) { ran = true }
      @registry.raise_event :foobar
      ran.should be_true
    end

    it "passes the argument list to event handlers" do
      params = nil
      @registry.on(:foobar) { |p1,p2| params = [p1,p2] }
      @registry.raise_event :foobar, :barfoo, :raboof
      params.should == [:barfoo, :raboof]
    end
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

  describe "#run_event" do
    it "TODO: some of run_events was split out into run_event, test that here"
  end

  describe "#run_events" do
    before(:each) do
      # XXX use sprocs as handlers will be serialized
      $invoked1, $invoked2 = false, false
      @h1 = SProc.new { $invoked1 = true }
      @h2 = SProc.new { $invoked2 = true }
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
      e = Event.new :id => 'foobar', :timestamp => (Time.now - 10)
      eh1 = EventHandler.new :event_id => 'foobar', :handlers => [@h1]
      eh2 = EventHandler.new :event_id => 'barfoo', :handlers => [@h2]
      @registry << eh1
      @registry << eh2
      @registry << e
      @registry.send :run_events
      $invoked1.should be_true
      $invoked2.should be_false
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
        }.should_not raise_error(Exception)
      end
    end

    it "deletes event in registry" do
      e = Event.new :id => 'eid',
                    :timestamp => (Time.now - 10),
                    :handlers => [@h1]
      @registry << e
      @registry.should_receive(:cleanup_event).
                with('eid')
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
        @registry.send :cleanup_event, 'eid'
      }.should change{@registry.entities.size}.by(-3)

      @registry.entities {|e|
        (e.is_a?(Event) && e.id == 'eid') ||
        (e.is_a?(EventHandler) && e.event_id == 'eid' && !e.persist)
      }.should be_empty
    end

    it "skips persistent handlers" do
      @registry.send :cleanup_event, 'eid'
      @registry.entities {|e|
        e.is_a?(EventHandler) && e.event_id == 'eid' && e.persist
      }.size.should == 1
    end
  end

  describe "#run_commands" do
    before(:each) do
      @c = Command.new
      @registry.stub(:entities).and_return([@c])
    end

    it "sets registry on command" do
      @c.should_receive(:registry=).with(@registry)
      @registry.send :run_commands
    end

    it "sets node on command" do
      @c.should_receive(:node=).with(@registry.node)
      @registry.send :run_commands
    end

    context "first hooks not run" do
      it "runs first hooks" do
        @c.should_receive(:run_hooks).with(:first)
        @registry.send :run_commands
      end
    end

    context "first hooks previously run" do
      it "does not runs first hooks" do
        @c.run_hooks :first
        @c.should_not_receive(:run_hooks).with(:first)
        @registry.send :run_commands
      end
    end

    it "runs before hooks" do
      @c.should_receive(:run_hooks).with(:first)
      @c.should_receive(:run_hooks).with(:before)
      @registry.send :run_commands
    end

    context "command should run" do
      before(:each) do
        @c.should_receive(:should_run?).and_return(true)
      end

      it "runs command" do
        @c.should_receive(:run!)
        @registry.send :run_commands
      end

      it "runs after hooks" do
        @c.should_receive(:run_hooks).with(:first)
        @c.should_receive(:run_hooks).with(:before)
        @c.should_receive(:run_hooks).with(:after)
        @registry.send :run_commands
      end
    end

    context "command should not run" do
      before(:each) do
        @c.should_receive(:should_run?).and_return(false)
      end

      it "does not run command" do
        @c.should_not_receive(:run!)
        @registry.send :run_commands
      end

      it "does not run after hooks" do
        @c.should_not_receive(:run_hooks).with(:after)
        @registry.send :run_commands
      end
    end

    context "command should be removed" do
      before(:each) do
        @c.should_receive(:remove?).and_return(true)
      end

      it "runs last hooks" do
        @c.should_receive(:run_hooks).with(:first)
        @c.should_receive(:run_hooks).with(:before)
        @c.should_receive(:run_hooks).with(:after)
        @c.should_receive(:run_hooks).with(:last)
        @registry.send :run_commands
      end

      it "deletes command" do
        @registry.should_receive(:delete)
        @registry.send :run_commands
      end
    end

    it "catches errors during command hooks" do
      @c.should_receive(:run_hooks).and_raise(Exception)
      lambda{
        @registry.send :run_commands
      }.should_not raise_error
    end

    it "catches errors during command" do
      @c.should_receive(:run!).and_raise(Exception)
      lambda{
        @registry.send :run_commands
      }.should_not raise_error
    end

    it "returns default command poll" do
      @registry.send(:run_commands).should == Registry::DEFAULT_COMMAND_POLL
    end
  end

  describe "#check_command" do
    it "removes all entities w/ the specified command id except last" do
      c1 = Command.new :id => 'cid', :exec_rate => 5
      c2 = Command.new :id => 'cid', :exec_rate => 15
      @registry << c1
      @registry << c2
      @registry.send :check_command, Command.new(:id => 'cid')
      res = @registry.entities { |e| e.id == 'cid' }

      res.size.should == 1
      res.first.exec_rate.should == 15
    end
  end

  describe "#save" do
    it "stores entities in json in io object" do
      @registry << OmegaTest::ServerEntity.new(:id => 1)
      @registry << OmegaTest::ServerEntity.new(:id => 2)

      sio = StringIO.new
      @registry.save(sio)
      s = sio.string

      s.should include('"id":1')
      s.should include('"id":2')
      s.should include('"json_class":"OmegaTest::ServerEntity"')
    end
  end

  describe "#restore" do
    it "retrieves entities from json in io object" do
      s = '{"json_class":"OmegaTest::ServerEntity","data":{"id":1,"val":null}}'+"\n"+
          '{"json_class":"OmegaTest::ServerEntity","data":{"id":2,"val":null}}'

      sio = StringIO.new
      sio.string = s

      @registry.restore s
      @registry.entities.size.should == 2
      @registry.entities.first.should == OmegaTest::ServerEntity.new(:id => 1, :val => nil)
    end
  end
end

end # module Server
end # module Omega
