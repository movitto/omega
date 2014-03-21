# Missions DSL Assignment Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/assignment'

module Missions
module DSL
  describe Assignment do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m = build(:mission)
    end

    describe "#store" do
      before(:each) do
        @lookup = proc { |m,n| 42 }
      end

      it "generates a proc" do
        Assignment.store('ship1', @lookup).should be_an_instance_of(Proc)
      end

      it "invokes specified lookup method" do
        @lookup.should_receive(:call).with(@m)
        Assignment.store('ship1', @lookup).call(@m)
      end

      it "stores result of lookup method in mission data" do
        Assignment.store('ship1', @lookup).call(@m)
        @m.mission_data['ship1'].should == 42
      end
    end # describe #store

    describe "#create_entity" do
      it "generates a proc" do
        Assignment.create_entity('ship1').should be_an_instance_of(Proc)
      end

      it "create and stores new ship in mission data" do
        @node.should_receive(:invoke)
        Assignment.create_entity('ship1', 'type' => :mining).call(@m)
        @m.mission_data['ship1'].should be_an_instance_of(Manufactured::Ship)
        @m.mission_data['ship1'].type.should == :mining
      end

      it 'generates a new id if not specified' do
        @node.should_receive(:invoke)
        Assignment.create_entity('ship1', 'type' => :mining).call(@m)
        @m.mission_data['ship1'].id.should_not be_nil
        @m.mission_data['ship1'].id.should =~ UUID_PATTERN

        Assignment.create_entity('ship1', :id => 'ship1', 'type' => :mining).call(@m)
        @m.mission_data['ship1'].id.should == 'ship1'
      end

      it "invokes manufactured::create_entity" do
        @node.should_receive(:invoke).
              with('manufactured::create_entity', an_instance_of(Manufactured::Ship))
        Assignment.create_entity('ship1', 'type' => :mining).call(@m)
      end
    end

    describe "#create_asteroid" do
      it "generates a proc" do
        Assignment.create_asteroid('ast').should be_an_instance_of(Proc)
      end

      it "creates and stores new asteroid in mission data" do
        @node.should_receive(:invoke)
        Assignment.create_asteroid('ast1', :name => 'ast1').call(@m)
        @m.mission_data['ast1'].should be_an_instance_of(Cosmos::Entities::Asteroid)
        @m.mission_data['ast1'].name.should == "ast1"
      end

      it 'generates a new id if not specified' do
        @node.should_receive(:invoke)
        Assignment.create_asteroid('ast1').call(@m)
        @m.mission_data['ast1'].id.should_not be_nil
        @m.mission_data['ast1'].id.should =~ UUID_PATTERN

        Assignment.create_asteroid('ast1', :id => 'ast2').call(@m)
        @m.mission_data['ast1'].id.should == 'ast2'
      end

      it 'sets the asteroid name if not specified' do
        @node.should_receive(:invoke)
        Assignment.create_asteroid('ast1').call(@m)
        @m.mission_data['ast1'].name.should_not be_nil
        @m.mission_data['ast1'].name.should =~ UUID_PATTERN

        Assignment.create_asteroid('ast1', :id => 'ast2').call(@m)
        @m.mission_data['ast1'].name.should == 'ast2'

        Assignment.create_asteroid('ast1', :name => 'ast3').call(@m)
        @m.mission_data['ast1'].name.should == 'ast3'
      end

      it "invokes cosmos::create_entity" do
        sys = build(:solar_system);
        @node.should_receive(:invoke).
              with('cosmos::create_entity',
                   an_instance_of(Cosmos::Entities::Asteroid))
        Assignment.create_asteroid('ast1', 'name' => 'ast1',
                                   :solar_system => sys).call(@m)
      end
    end

    describe "#create_resource" do
      before(:each) do
        @m.mission_data['ast1'] = Cosmos::Entities::Asteroid.new(:id => 'ast1_id')
      end

      it "generates a proc" do
        Assignment.create_resource('ast1', :material_id => 'element-gold').
                   should be_an_instance_of(Proc)
      end

      it "invokes cosmos::set_resource" do
        @node.should_receive(:notify).
              with { |*args|
                args[0].should == "cosmos::set_resource"
                args[1].should be_an_instance_of(Cosmos::Resource)
                args[1].material_id.should == 'element-gold'
              }
        Assignment.create_resource('ast1', :material_id => 'element-gold').
                   call(@m)
      end

      it "generates a new resource id if not set" do
        @node.should_receive(:notify).
          with { |*args|
            args[1].id.should_not be_nil
            args[1].id.should =~ UUID_PATTERN
          }
        Assignment.create_resource('ast1', :material_id => 'element-gold').
                   call(@m)
      end
    end

    describe "#add_resource" do
      before(:each) do
        @m.mission_data['ast1'] = Cosmos::Resource.new(:id => 'ast1_id')
      end

      it "generates a proc" do
        Assignment.add_resource('ast1', :material_id => 'element-gold').
                   should be_an_instance_of(Proc)
      end

      it "invokes cosmos::add_resource" do
        @node.should_receive(:notify).
              with { |*args|
                args[0].should == "manufactured::add_resource"
                args[1].should == 'ast1_id'
                args[2].should be_an_instance_of(Cosmos::Resource)
                args[2].material_id.should == 'element-gold'
              }
        Assignment.add_resource('ast1', :material_id => 'element-gold').
                   call(@m)
      end

      it "generates a new resource id if not set" do
        @m.mission_data['ship1'] = build(:ship)
        @node.should_receive(:notify).
          with { |*args|
            args[2].id.should_not be_nil
            args[2].id.should =~ UUID_PATTERN
          }
        Assignment.add_resource('ship1', :material_id => 'element-gold').
                   call(@m)
      end
    end

    describe "#subscribe_to" do
      before(:each) do
        @handler = proc { |m, n, e| }
      end

      it "generates a proc" do
        Assignment.subscribe_to('ship1', 'destroyed', @handler ).
                   should be_an_instance_of(Proc)
      end

      it "looks up string entity in mission data" do
        @node.should_receive(:invoke)
        sh = build(:ship)
        @m.mission_data['ship1'] = sh
        sh.should_receive(:id).twice
        Assignment.subscribe_to('ship1', 'destroyed', @handler ).call(@m)
      end

      it "handles multiple entities / handlers" do
        sh = build(:ship)
        handler1 = proc { |m, n, e| }

        @node.stub(:invoke) # stub out invoke
        @m.mission_data['ship1'] = build(:ship, :id => 'ship1')
        Assignment.subscribe_to(['ship1', sh], 'destroyed',
                                [@handler, handler1] ).call(@m)
        sh1 = Missions::RJR.registry.safe_exec{ |es|
                es.find { |e| e.event_id == 'ship1_destroyed'} }
        sh2 = Missions::RJR.registry.safe_exec{ |es|
                es.find { |e| e.event_id == sh.id + '_destroyed'} }
        sh1.should_not be_nil
        sh2.should_not be_nil

        e = Omega::Server::Event.new
        @handler.should_receive(:call).with(@m, e).exactly(2).times
        handler1.should_receive(:call).with(@m, e).exactly(2).times
        sh1.handlers.first.call e
        sh2.handlers.first.call e
      end

      it "handles multiple entities retrieved from mission data" do
        @node.stub(:invoke) # stub out invoke
        @m.mission_data['ship1'] = [build(:ship, :id => 'ship1'),
                                    build(:ship, :id => 'ship2')]
        Assignment.subscribe_to('ship1', 'destroyed', @handler ).call(@m)

        sh1 = Missions::RJR.registry.entity{ |e| e.event_id == 'ship1_destroyed'}
        sh2 = Missions::RJR.registry.entity{ |e| e.event_id == 'ship1_destroyed'}
        sh1.should_not be_nil
        sh2.should_not be_nil
      end

      it "adds events handler for manufactured event" do
        @node.stub(:invoke) # stub out invoke

        @node.should_receive(:invoke)
        @m.mission_data['ship1'] = build(:ship, :id => 'ship1')
        Assignment.subscribe_to('ship1', 'destroyed', @handler ).call(@m)
        Missions::RJR.registry.entity{ |e| e.event_id == 'ship1_destroyed'}.
                               should_not be_nil
      end

      context "on manufactured event" do
        it "invokes specified handler" do
          sh = build(:ship)
          @node.should_receive(:invoke)
          Assignment.subscribe_to(sh, 'destroyed', @handler).call(@m)
          handler = Missions::RJR.registry.safe_exec{ |entities| entities.last }

          e = Omega::Server::Event.new
          @handler.should_receive(:call).with(@m, e)
          handler.handlers.first.call e
        end
      end

      it "invokes manufactured::subscribe to" do
        sh = build(:ship)
        @node.should_receive(:invoke).
              with('manufactured::subscribe_to', sh.id, 'destroyed')
        Assignment.subscribe_to(sh, 'destroyed', @handler ).call(@m)
      end
    end

    describe "#schedule_expiration_events" do
      before(:each) do
        @m.assigned_time = 1000
        @m.timeout = 500
      end

      it "generates a proc" do
        Assignment.schedule_expiration_events.should be_an_instance_of(Proc)
      end

      it "creates new event in local registry" do
        Assignment.schedule_expiration_events.call(@m)
        evnt = Missions::RJR.registry.entity{ |e| e.id = "mission-#{@m.id}-expired" }
        evnt.should_not be_nil
        evnt.should be_an_instance_of(Missions::Events::Expired)
        evnt.timestamp.should == @m.assigned_time + @m.timeout
      end

      context "event execution" do
        it "invokes mission.failed!" do
          Assignment.schedule_expiration_events.call(@m)
          evnt = Missions::RJR.registry.safe_exec{ |entities| entities.last }
          evnt.registry = Missions::RJR.registry
          @m.should_receive(:failed!)
          evnt.handlers.first.call
        end
      end
    end
  end # describe Assignment
end # module Assignment
end # module DSL
