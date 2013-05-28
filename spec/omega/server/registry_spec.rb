# Omega Server Registry tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'thread'
require 'stringio'

require 'spec_helper'

require 'rjr/common' # for eigenclass
require 'omega/server/registry'

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
  end

  describe "#clear" do
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
        @registry.validation = proc { |entities, e|
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

  describe "#safe_exec" do
    it "safely executes a block of code" do
      @registry.safe_exec {
        proc {
          @registry.safe_exec
        }.should raise_error(ThreadError, "deadlock; recursive locking")
      }
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
