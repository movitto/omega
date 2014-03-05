# missions dsl module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl'
require 'rjr/common'

require 'missions/events/users'

module Missions
module DSL
  module Client
    describe Proxy do
      describe "::method_missing" do
        context "dsl method invoked on Proxy" do
          it "returns new Proxy encapsulating method" do
            st = build(:station)
            p = Proxy.docked_at st
            p.should be_an_instance_of(Proxy)
            p.dsl_category.should == "Requirements"
            p.dsl_method.should   == "docked_at"
            p.params.should == [st]
          end
        end

        context "non-dsl method invoked on Proxy" do
          it "returns nil" do
            n = Proxy.foobar
            n.should be_nil
          end
        end
      end

      describe "::resolve" do
        it "resolves all proxy references in all mission callbacks" do
          m = build(:mission)
          pr1 = proc {}
          proxy1 = Proxy.new

          m.requirements << pr1
          m.requirements << proxy1

          proxy1.should_receive(:resolve)
          Proxy.resolve(:mission => m)
        end
      end

      describe "#resolve" do
        before(:each) do
          @p = Proxy.new :dsl_category => Missions::DSL::Requirements,
                         :dsl_method   => :docked_at
        end

        context "invalid dsl category" do
          it "returns nil" do
            p = Proxy.new :dsl_category => 'Foobar'
            p.resolve.should be_nil
          end
        end

        context "invalid dsl method" do
          it "returns nil" do
            p = Proxy.new :dsl_category => 'Requirements',
                          :dsl_method   => 'create_entity'
            p.resolve.should be_nil
          end
        end

        it "resolves all proxy params" do
          p = Proxy.new
          @p.params << p
          p.should_receive(:resolve)
          @p.resolve
        end

        it "invokes dsl category method with params and return result" do
          @p.params << 42
          DSL::Requirements.should_receive(:docked_at).with(42).and_return(24)
          @p.resolve.should == 24
        end
      end

      describe "#to_json" do
        it "returns proxy in json format" do
          p = Proxy.new :dsl_category => 'Query',
                        :dsl_method => 'check_mining_quantity',
                        :params => [42]
          j = p.to_json
          j.should include('"json_class":"Missions::DSL::Client::Proxy"')
          j.should include('"dsl_category":"Query"')
          j.should include('"dsl_method":"check_mining_quantity"')
          j.should include('"params":[42]')
        end
      end

      describe "#json_create" do
        it "returns proxy from json format" do
          j = '{"json_class":"Missions::DSL::Client::Proxy","data":{"dsl_category":"Query","dsl_method":"check_mining_quantity","params":[42]}}'
          p = ::RJR.parse_json(j)

          p.class.should == Missions::DSL::Client::Proxy
          p.dsl_category.should == 'Query'
          p.dsl_method.should == 'check_mining_quantity'
          p.params.should == [42]
        end
      end
    end
  end

  describe Requirements do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m = build(:mission)
      @u = build(:user)
    end

    describe "#shared_station" do
      it "generates a proc" do
        Requirements.shared_station.should be_an_instance_of(Proc)
      end

      it "retrieves ships owned by mission creator and assigning_to user" do
        @node.should_receive(:invoke).
              with('manufactured::get_entities',
                   'of_type', 'Manufactured::Ship',
                   'owned_by', @m.creator.id).and_return([])

        @node.should_receive(:invoke).
              with('manufactured::get_entities',
                   'of_type', 'Manufactured::Ship',
                   'owned_by', @u.id).and_return([])
        Requirements.shared_station.call @m, @u
      end

      context "users have ships with a shared docked station" do
        it "returns true" do
          st = build(:station)
          sh1 = build(:ship, :docked_at => st)
          sh2 = build(:ship, :docked_at => st)
          @node.should_receive(:invoke).once.and_return([sh1])
          @node.should_receive(:invoke).once.and_return([sh2])
          Requirements.shared_station.call(@m, @u).should be_true
        end
      end

      context "users do not have ships with a shared docked station" do
        it "returns false" do
          @node.should_receive(:invoke).once.and_return([])
          @node.should_receive(:invoke).once.and_return([])
          Requirements.shared_station.call(@m, @u).should be_false
        end
      end
    end # dscribe shared_station

    describe "#docked_at" do
      before(:each) do
        @station = build(:station)
      end

      it "generates a proc" do
        Requirements.docked_at(@station).should be_an_instance_of(Proc)
      end

      it "retrieve ships owned by assigning_to user" do
        @node.should_receive(:invoke)
             .with('manufactured::get_entities',
                   'of_type', 'Manufactured::Ship',
                   'owned_by', @u.id).and_return([])
        Requirements.docked_at(@station).call @m, @u
      end

      context "assigning_to user has ship docked at the specified station" do
        it "returns true" do
          @node.should_receive(:invoke).and_return([build(:ship, :docked_at => @station)])
          Requirements.docked_at(@station).call(@m, @u).should be_true
        end
      end

      context "assigning_to user does not have ship docked at the specified station" do
        it "returns false" do
          @node.should_receive(:invoke).and_return([]);
          Requirements.docked_at(@station).call(@m, @u).should be_false
        end
      end
    end # describe docked_at
  end # describe Requirements

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

    describe "#schedule_expiration_event" do
      before(:each) do
        @m.assigned_time = 1000
        @m.timeout = 500
      end

      it "generates a proc" do
        Assignment.schedule_expiration_event.should be_an_instance_of(Proc)
      end

      it "creates new event in local registry" do
        Assignment.schedule_expiration_event.call(@m)
        evnt = Missions::RJR.registry.entity{ |e| e.id = "mission-#{@m.id}-expired" }
        evnt.should_not be_nil
        evnt.should be_an_instance_of(Omega::Server::Event)
        evnt.timestamp.should == @m.assigned_time + @m.timeout
      end

      context "event execution" do
        it "invokes mission.failed!" do
          Assignment.schedule_expiration_event.call(@m)
          evnt = Missions::RJR.registry.safe_exec{ |entities| entities.last }
          @m.should_receive(:failed!)
          evnt.handlers.first.call
        end
      end
    end
  end # describe Assignment

  describe Event do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m    = build(:mission)
    end

    describe "#resource_collected" do
      before(:each) do
        @sh = build(:ship)
        @rs = build(:resource)
        @evnt = Missions::Events::Manufactured.new 'resource_collected', @sh, @rs, 50
      end

      it "generates a proc" do
        Event.resource_collected.should be_an_instance_of(Proc)
      end

      it "adds collected resource to mission data" do
        Query.should_receive(:check_mining_quantity).twice.and_return(proc{ false })

        Event.resource_collected.call(@m, @evnt)
        @m.mission_data['resources'][@rs.material_id].should == 50

        Event.resource_collected.call(@m, @evnt)
        @m.mission_data['resources'][@rs.material_id].should == 100
      end

      it "invokes Query.check_mining_quantity" do
        cmq = Query.check_mining_quantity
        Query.should_receive(:check_mining_quantity).and_return(cmq)
        cmq.should_receive(:call).with(@m)
        Event.resource_collected.call(@m, @evnt)
      end

      context "check_mining_quantity returns true" do
        it "invokes Event.create_victory_event" do
          Query.should_receive(:check_mining_quantity).and_return(proc { true })
          cve = Event.create_victory_event
          Event.should_receive(:create_victory_event).and_return(cve)
          cve.should_receive(:call).with(@m, @evnt)
          Event.resource_collected.call(@m, @evnt)
        end
      end
    end

    describe "#transferred_out" do
      before(:each) do
        @src  = build(:ship)
        @dst  = build(:ship)
        @rs   = build(:resource)
        @evnt = Missions::Events::Manufactured.new 'transferred_to', @src, @dst, @rs, 50
      end

      it "generates a proc" do
        Event.transferred_out.should be_an_instance_of(Proc)
      end

      it "set last_transfer on mission data" do
        Query.should_receive(:check_transfer).and_return(proc{ false })
        Event.transferred_out.call(@m, @evnt)
        @m.mission_data['last_transfer'].should ==
          { 'dst' => @dst, 'rs' => @rs.material_id, 'q' => @rs.quantity }
      end

      it "invokes Query.check_transfer" do
        ct = Query.check_transfer
        Query.should_receive(:check_transfer).and_return(ct)
        ct.should_receive(:call).with(@m)
        Event.transferred_out.call(@m, @evnt)
      end

      context "check_transfer returns true" do
        it "invokes Event.create_victory_event" do
          Query.should_receive(:check_transfer).and_return(proc { true })
          cve = Event.create_victory_event
          Event.should_receive(:create_victory_event).and_return(cve)
          cve.should_receive(:call).with(@m, @evnt)
          Event.transferred_out.call(@m, @evnt)
        end
      end
    end

    describe "#entity_destroyed" do
      it "generates a proc" do
        Event.entity_destroyed.should be_an_instance_of(Proc)
      end

      it "adds events to mission data" do
        Event.entity_destroyed.call(@m, 42)
        @m.mission_data['destroyed'].should == [42]
      end
    end

    describe "#collected_loot" do
      before(:each) do
        @sh  = build(:ship)
        @rs  = build(:resource)
        @evnt = Missions::Events::Manufactured.new 'collected_loot', @sh, @rs
      end

      it "generates a proc" do
        Event.collected_loot.should be_an_instance_of(Proc)
      end

      it "adds collected loot to mission data" do
        Query.should_receive(:check_loot).and_return(proc{ false })
        Event.collected_loot.call(@m, @evnt)
        @m.mission_data['loot'].should == [@rs]
      end

      it "invokes Query.check_loot" do
        cl = Query.check_loot
        Query.should_receive(:check_loot).and_return(cl)
        cl.should_receive(:call).with(@m)
        Event.collected_loot.call(@m, @evnt)
      end

      context "check_loot return true" do
        it "invokes Event.create_victory_event" do
          Query.should_receive(:check_loot).and_return(proc { true })
          cve = Event.create_victory_event
          Event.should_receive(:create_victory_event).and_return(cve)
          cve.should_receive(:call).with(@m, @evnt)
          Event.collected_loot.call(@m, @evnt)
        end
      end
    end

    describe "#create_victory_event" do
      before(:each) do
        @m.assigned_to = build(:user)
      end

      it "generates a proc" do
        Event.create_victory_event.should be_an_instance_of(Proc)
      end

      it "invokes mission.victory!" do
        @m.should_receive(:victory!)
        Event.create_victory_event.call(@m, 42)
      end

      it "create new event in local registry" do
        Event.create_victory_event.call(@m, 42)
        evnt = Missions::RJR.registry.entities.first
        evnt.should be_an_instance_of(Omega::Server::Event)
        evnt.id.should == "mission-#{@m.id}-victory"
      end
    end
  end # describe Event

  describe EventHandler do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
    end

    describe "#on_event_create_entity" do
      it "returns nil by default" do
        EventHandler.on_event_create_entity.should be_nil
      end

      context "registered_user event" do
        before(:each) do
          @user  = build(:user)
          @event = Missions::Events::Users.new :users_event_args =>
                     ['registered_user', @user]
        end

        it "generates a proc" do
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       should be_an_instance_of(Proc)
        end

        it "creates a new id if not specified" do
          @node.should_receive(:invoke).with { |*args|
            args[1].id.should =~ UUID_PATTERN
          }
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       call @event
        end

        it "retrieves user id from registered_user event args" do
          @node.should_receive(:invoke).with { |*args|
            args[1].user_id.should == @user.id
          }
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       call @event
        end

        it "creates new entity of the specified type" do
          @node.should_receive(:invoke).with { |*args|
            args[1].should be_an_instance_of(Manufactured::Ship)
          }
          EventHandler.on_event_create_entity(:event => 'registered_user',
                                              :entity_type => 'Manufactured::Ship').
                       call @event
        end

        it "invokes manufactured::create_entity to create entity" do
          @node.should_receive(:invoke).with { |*args|
            args[0].should == 'manufactured::create_entity'
          }
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       call @event
        end
      end
    end

    describe "#on_event_add_role" do
      it "returns nil by default" do
        EventHandler.on_event_add_role.should be_nil
      end

      context "registered_user event" do
        before(:each) do
          @user  = build(:user)
          @event = Missions::Events::Users.new :users_event_args =>
                     ['registered_user', @user]
        end

        it "generates a proc" do
          EventHandler.on_event_add_role(:event => 'registered_user').
                       should be_an_instance_of(Proc)
        end

        it "retrieves user id from registered_user event args" do
          @node.should_receive(:invoke).with { |*args|
            args[1].should == @user.id
          }
          EventHandler.on_event_add_role(:event => 'registered_user').
                       call @event
        end

        it "invokes users::add_role" do
          @node.should_receive(:invoke).with { |*args|
            args[0].should == 'users::add_role'
            args[2].should == 'regular_user'
          }
          EventHandler.on_event_add_role(:event => 'registered_user',
                                         :role  => 'regular_user').
                       call @event
        end
      end
    end
  end

  describe Query do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m = build(:mission)
    end

    describe "#check_entity_hp" do
      before(:each) do
        @sh = build(:ship)
        @m.mission_data['ship1'] = @sh
      end

      it "generates a proc" do
        Query.check_entity_hp('ship1').should be_an_instance_of(Proc)
      end

      it "invokes manufactured::get_entity" do
        @node.should_receive(:invoke).
              with('manufactured::get_entity', @sh.id).and_return(nil)
        Query.check_entity_hp('ship1').call(@m)
      end

      context "entity hp > 0" do
        it "returns true" do
          @sh.hp = 00
          @node.should_receive(:invoke).and_return(@sh)
          Query.check_entity_hp('ship1').call(@m).should be_true
        end
      end

      context "entity hp == 0" do
        it "returns false" do
          @sh.hp = 20
          @node.should_receive(:invoke).and_return(@sh)
          Query.check_entity_hp('ship1').call(@m).should be_false
        end
      end
    end

    describe "#check_mining_quantity" do
      before(:each) do
        @m.mission_data['resources'] = {}
        @m.mission_data['target']    = 'metal-alluminum'
        @m.mission_data['quantity']  = 50
      end

      it "generates a proc" do
        Query.check_mining_quantity.should be_an_instance_of(Proc)
      end

      context "target quantity >= quantity" do
        it "returns true" do
          @m.mission_data['resources']['metal-alluminum'] = 100
          Query.check_mining_quantity.call(@m).should be_true
        end
      end
      context "target quantity < quantity" do
        it "returns false" do
          @m.mission_data['resources']['metal-alluminum'] = 10
          Query.check_mining_quantity.call(@m).should be_false
        end
      end
    end

    describe "#check_transfer" do
      before(:each) do
        @dst = build(:ship)
        @rs  = build(:resource)
        @m.mission_data['check_transfer'] =
          { 'dst' => @dst, 'rs' => @rs.material_id, 'q' => @rs.quantity }
      end

      it "generates a proc" do
        Query.check_transfer.should be_an_instance_of(Proc)
      end

      context "last transfer matches check" do
        it "returns true" do
          @m.mission_data['last_transfer'] =
          { 'dst' => @dst, 'rs' => @rs.material_id, 'q' => @rs.quantity }
          Query.check_transfer.call(@m).should be_true
        end
      end

      context "last transfer does not match check " do
        it "returns false" do
          @rs = build(:resource)
          @m.mission_data['last_transfer'] =
            { 'dst' => @dst, 'rs' => @rs.material_id, 'q' => @rs.quantity }
          Query.check_transfer.call(@m).should be_false
        end
      end
    end

    describe "#check_loot" do
      before(:each) do
        @rs  = build(:resource)
        @m.mission_data['check_loot'] =
          {'res' => @rs.material_id, 'q' => @rs.quantity}
      end

      it "generates a proc" do
        Query.check_loot.should be_an_instance_of(Proc)
      end

      context "loot matching check found" do
        it "returns true" do
          @m.mission_data['loot'] = [@rs]
          Query.check_loot.call(@m).should be_true
        end
      end
      context "no loot matching check found" do
        it "returns false" do
          @m.mission_data['loot'] = [build(:resource)]
          Query.check_loot.call(@m).should be_false
        end
      end
    end

    describe "#user_ships" do
      before(:each) do
        @m.assigned_to = build(:user)
      end

      it "generates a proc" do
        Query.user_ships.should be_an_instance_of(Proc)
      end

      it "invokes manufactured::get_entity" do
        @node.should_receive(:invoke).
              with('manufactured::get_entity', 'of_type', 'Manufactured::Ship',
                   'owned_by', @m.assigned_to_id).and_return([])
        Query.user_ships.call(@m)
      end

      it "filters retrieved entities by specified filter" do
        filter = { :type => :mining }
        sh1 = build(:ship, :type => :mining)
        sh2 = build(:ship, :type => :corvette)
        @node.should_receive(:invoke).and_return([sh1, sh2])
        Query.user_ships(filter).call(@m).should == [sh1]
      end
    end

    describe "#user_ship" do
      it 'generates a proc' do
        Query.user_ship.should be_an_instance_of(Proc)
      end

      it "invokes users_ships" do
        p = proc {}
        Query.should_receive(:user_ships).and_return(p)
        p.should_receive(:call).and_return([42])
        Query.user_ship.call.should == 42
      end
    end
  end # describe Query

  describe Resolution do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
      @m = build(:mission)
    end

    describe "#add_reward" do
      it "generates a proc" do
        Resolution.add_reward(build(:resource)).should be_an_instance_of(Proc)
      end

      it "invokes Query.user_ships" do
        us = Query.user_ships
        Query.should_receive(:user_ships).and_return(us)
        us.should_receive(:call).with(@m).and_return([build(:ship)])
        @node.should_receive(:invoke)
        Resolution.add_reward(build(:resource)).call(@m)
      end

      it "invokes manufactured::add_resource" do
        rs = build(:resource)
        sh = build(:ship)
        Query.should_receive('user_ships').and_return(proc { [sh] })
        @node.should_receive(:invoke).
              with('manufactured::add_resource', sh.id, rs)
        Resolution.add_reward(rs).call(@m)
      end
    end

    describe "#update_user_attributes" do
      before(:each) do
        @u = build(:user)
        @m.assigned_to = @u
      end
      it "generates a proc" do
        Resolution.update_user_attributes.should be_an_instance_of(Proc)
      end

      context "mission is victorious" do
        it "updates MissionsCompleted attribute" do
          @m.victory!
          @node.should_receive(:invoke).
             with('users::update_attribute', @u.id,
                  Users::Attributes::MissionsCompleted.id, 1 )

          Resolution.update_user_attributes.call(@m, @n)
        end
      end
      context "mission failed" do
        it "updates MissionsFailed attribute" do
          @m.failed!
          @node.should_receive(:invoke).
             with('users::update_attribute', @u.id,
                  Users::Attributes::MissionsFailed.id, 1 )

          Resolution.update_user_attributes.call(@m, @n)
        end
      end
    end

    describe "#cleanup_events" do
      before(:each) do
        @sh = build(:ship)
        @m.mission_data[@sh.id] = @sh

        Missions::RJR.registry <<
          Omega::Server::EventHandler.new(:event_id => "#{@sh.id}_destroyed")

        @eid = "mission-#{@m.id}-expired"
        Missions::RJR.registry << Omega::Server::Event.new(:id => @eid)
      end

      it "generates a proc" do
        Resolution.cleanup_events(@sh.id, 'destroyed').should be_an_instance_of(Proc)
      end

      it "invokes manufactured::remove_callbacks on each entity" do
        @node.should_receive(:invoke).
              with('manufactured::remove_callbacks', @sh.id)
        Resolution.cleanup_events(@sh.id, 'destroyed').call(@m)
      end

      it "removes each entity/event handler" do
        @node.should_receive(:invoke)
        Missions::RJR.registry.should_receive(:cleanup_event).
                               with("#{@sh.id}_destroyed").
                               and_call_original
        Missions::RJR.registry.should_receive(:cleanup_event).
                               once.and_call_original
        lambda{
          Resolution.cleanup_events(@sh.id, 'destroyed').call(@m)
        }.should change{Missions::RJR.registry.entities.size}.by(-2)
      end

      it "removes mission expired event" do
        @node.should_receive(:invoke)
        Missions::RJR.registry.should_receive(:cleanup_event).
                               with(@eid).and_call_original
        Missions::RJR.registry.should_receive(:cleanup_event).
                               once.and_call_original
        lambda{
          Resolution.cleanup_events(@sh.id, 'destroyed').call(@m)
        }.should change{Missions::RJR.registry.entities.size}.by(-2)
      end
    end

    describe "#recycle_mission" do
      it "generates a proc" do
        Resolution.recycle_mission.should be_an_instance_of(Proc)
      end

      it "clones mission" do
        @m.should_receive(:clone).and_call_original
        @node.should_receive(:invoke)
        Resolution.recycle_mission.call(@m)
      end

      it "clears new mission assignment" do
        mis = build(:mission)
        @m.should_receive(:clone).and_return(mis)
        mis.should_receive(:clear_assignment!)
        @node.should_receive(:invoke)
        Resolution.recycle_mission.call(@m)
      end

      it "invokes missions::create_mission" do
        mis = build(:mission)
        @m.should_receive(:clone).and_return(mis)
        @node.should_receive(:invoke).
              with('missions::create_mission', mis)
        Resolution.recycle_mission.call(@m)
      end
    end
  end # describe Resolution

end # describe DSL
end # module Missions
