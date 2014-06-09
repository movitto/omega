# Omega Server events DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/events'
require 'omega/server/dsl/events'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  describe "#delete_event_handler_for" do
    before(:each) do
      @eh1 = Omega::Server::EventHandler.new(:event_id => 'registered_user-10',
                                             :event_type => 'registered_user',
                                             :endpoint_id => 'node1')
      @registry = Users::Registry.new
      @registry << @eh1
    end

    it "removes registry handler for specified event id/endpoint" do
      delete_event_handler_for :event_id => 'registered_user-10',
                               :endpoint_id => 'node1',
                               :registry => @registry
      @registry.entities.should be_empty
    end

    it "removes registry handler for specified event type/endpoint" do
      delete_event_handler_for :event_type => 'registered_user',
                               :endpoint_id => 'node1',
                               :registry => @registry
      @registry.entities.should be_empty
    end
  end

  describe "#remove_callbacks_for" do
    before(:each) do
    end

    context "registry is specified" do
      it "invokes remove_callbacks_for with registry entities" do
        r = Object.new
        r.extend Omega::Server::Registry
        entities = []
        criteria = {}
        r.should_receive(:safe_exec).and_yield(entities)
        should_receive(:remove_callbacks_for).with(entities, criteria)
        should_receive(:remove_callbacks_for).with(r, criteria).and_call_original
        remove_callbacks_for(r, criteria)
      end
    end

    context "class specified" do
      it "only processes entities matching class" do
        entities = [Motel::Location.new, Manufactured::Ship.new]
        entities.last.should_not_receive(:callbacks)
        remove_callbacks_for(entities, :class => Motel::Location)
      end
    end

    context "id specified" do
      it "only processes entity matching id" do
        entities = [Motel::Location.new(:id => 1), Motel::Location.new(:id => 2)]
        entities.last.should_not_receive(:callbacks)
        remove_callbacks_for(entities, :id => 1)
      end
    end

    context "endpoint is specified" do
      it "only removes cbs matching endpoint" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:endpoint_id => 'e1'),
           Omega::Server::Callback.new(:endpoint_id => 'e2')]
        lambda{
          remove_callbacks_for([entity], :endpoint => 'e2')
        }.should change{entity.callbacks.size}.by(-1)
        entity.callbacks.first.endpoint_id.should == 'e1'
      end
    end

    context "type is specified" do
      it "only removes cbs matching type" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type => 'e1'),
           Omega::Server::Callback.new(:event_type => 'e2')]
        lambda{
          remove_callbacks_for([entity], :type => 'e2')
        }.should change{entity.callbacks.size}.by(-1)
        entity.callbacks.first.event_type.should == 'e1'
      end
    end

    context "multiple criteria are specified" do
      it "only process entities/ removes cbs matching all criteria" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei1'),
           Omega::Server::Callback.new(:event_type  => 'ev2',
                                       :endpoint_id => 'ei2'),
           Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei2'),]
        lambda{
          remove_callbacks_for([entity], :type => 'ev1', :endpoint => 'ei2')
        }.should change{entity.callbacks.size}.by(-1)
        entity.callbacks.first.event_type.should == 'ev1'
        entity.callbacks.last.event_type.should  == 'ev2'
      end
    end

    context "callbacks is a event_type => cb_array hash" do
      it "removes callbacks from event_type arrays" do
        entity = Motel::Location.new
        entity.callbacks = {
          :movement => [Omega::Server::Callback.new(:event_type => :movement,
                                                    :endpoint_id => 'ev1'),
                        Omega::Server::Callback.new(:event_type => :movement,
                                                    :endpoint_id => 'ev2')],
          :rotation => [Omega::Server::Callback.new(:event_type => :rotation,
                                                    :endpoint_id => 'ev2')]
        }

        lambda{
        lambda{
          remove_callbacks_for([entity], :type => :movement, :endpoint => 'ev2')
        }.should change{entity.callbacks[:movement].size}.by(-1)
        }.should_not change{entity.callbacks[:rotation].size}
      end

      it "cleans up callbacks" do
        entity = Motel::Location.new
        entity.callbacks = {
          :movement => [Omega::Server::Callback.new(:event_type => :movement)]
        }

        remove_callbacks_for([entity], :type => :movement)
        entity.callbacks.has_key?(:movement).should be_false
      end
    end

    context "callbacks is an array of cbs" do
      it "removes callbacks from array" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei1'),
           Omega::Server::Callback.new(:event_type  => 'ev2',
                                       :endpoint_id => 'ei2')]
        lambda{
          remove_callbacks_for([entity], :type => 'ev1', :endpoint => 'ei1')
        }.should change{entity.callbacks.size}.by(-1)
      end

      it "cleans up callbacks" do
        entity = Manufactured::Ship.new
        entity.callbacks =
          [Omega::Server::Callback.new(:event_type  => 'ev1',
                                       :endpoint_id => 'ei1')]
        remove_callbacks_for([entity], :type => 'ev1', :endpoint => 'ei1')
        entity.callbacks.should be_empty
      end
    end
  end

  describe "#handle_node_closed" do
    before(:each) do
      @node = RJR::Node.new
    end

    it "subscribes to node closed event" do
      @node.should_receive(:on).with(:closed)
      handle_node_closed @node
    end

    context "on node closed" do
      it "invokes registered callback" do
        cb = proc {}
        handle_node_closed @node, &cb

        cb.should_receive(:call).with(@node)
        node.send :connection_event, :closed
      end
    end
  end
end # describe DSL
end # module Server
end # module Omega
