# Mining Command tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/commands/mining'

module Manufactured::Commands
describe Mining do
  describe "#id" do
    it "should be unique per miner" do
      m = Mining.new
      m.ship = build(:ship)
      m.id.should == 'mining-cmd-' + m.ship.id.to_s
    end
  end

  describe "#gen_resource" do
    it "creates new resource from local copy" do
      m = Mining.new :resource => build(:resource), :ship => build(:ship)
      r = m.send(:gen_resource)
      r.should be_an_instance_of(Cosmos::Resource)
      r.should_not eq(m.resource)
      r.id.should == m.resource.id
      r.entity.should == m.resource.entity
      r.quantity.should == 20
    end

    context "ship mining quantity < ship cargo space and resource quantity" do
      it "sets quantity to ship mining quantity" do
        m = Mining.new :resource => build(:resource),
                       :ship     => build(:ship, :mining_quantity => 10)
        r = m.send(:gen_resource)
        r.quantity.should == m.ship.mining_quantity
      end
    end

    context "resource quantity < ship cargo space and ship mining quantity" do
      it "sets quantity to resource quantity" do
        m = Mining.new :resource => build(:resource, :quantity => 5),
                       :ship     => build(:ship, :mining_quantity => 10)
        r = m.send(:gen_resource)
        r.quantity.should == m.resource.quantity
      end
    end

    context "ship cargo space < resource quantity and ship mining quantity" do
      it "sets quantity to ship cargo space" do
        m = Mining.new :resource => build(:resource, :quantity => 15),
                       :ship     => build(:ship, :mining_quantity => 10,
                                                 :cargo_capacity => 5)
        r = m.send(:gen_resource)
        r.quantity.should == m.ship.cargo_capacity
      end
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      m = Mining.new
      m.ship.should be_nil
      m.resource.should be_nil
    end

    it "sets attributes" do
      s = build(:ship)
      r = build(:resource)
      m = Mining.new :ship => s, :resource => r
      m.ship.should == s
      m.resource.should == r
    end
  end

  describe "#update" do
    it "updates resource" do
      r = build(:resource)
      m = Mining.new :resource => r
      m1 = Mining.new
      m1.update m
      m1.resource.should == r
    end
  end

  describe "#first_hook" do
    before(:each) do
      setup_manufactured

      @s = build(:ship)
      @r = build(:resource)
      @m = Mining.new :ship => @s, :resource => @r
      @m.registry= @registry
    end

    it "starts mining" do
      @s.should_receive(:start_mining).with(@r)
      @m.first_hook
    end

    it "updates registry ship" do
      @m.should_receive(:update_registry).with(@s)
      @m.first_hook
    end
  end

  describe "#before_hook" do
    before(:each) do
      setup_manufactured

      @s = create(:valid_ship)
      @r = build(:resource)
      @m = Mining.new :ship => @s, :resource => @r
      @m.registry= @registry
      @m.node = Manufactured::RJR.node
    end

    it "retrieves ship" do
      @m.should_receive(:retrieve).with(@s.id).and_call_original
      @m.before_hook
    end

    it "updates ship location from motel" do
      @m.should_receive(:invoke).
         with('motel::get_location',
              'with_id', @s.location.id).and_call_original
      @m.should_receive(:invoke).at_least(1).times.and_call_original
      @m.before_hook
    end

    it "retrieves resource" do
      @m.should_receive(:invoke).with('cosmos::get_resource', @r.id).and_call_original
      @m.should_receive(:invoke).at_least(1).times.and_call_original
      @m.before_hook
    end

    context "error during resource retrieval" do
      before(:each) do
        @m.should_receive(:invoke).
           with('cosmos::get_resource', @r.id).
           and_raise(Exception)
        @m.should_receive(:invoke).at_least(1).times.and_call_original
      end

      it "sets quantity to 0" do
        @m.before_hook
        @m.resource.quantity.should == 0
      end

      it "sets error to true" do
        @m.before_hook
        @m.instance_variable_get(:@error).should be_true
      end
    end
  end

  describe "#after_hook" do
    before(:each) do
      setup_manufactured

      @s = create(:valid_ship)
      @r = build(:resource)
      @m = Mining.new :ship => @s, :resource => @r
      @m.registry= @registry
      @m.node = Manufactured::RJR.node
    end

    it "saves ship in registry" do
      @m.should_receive(:update_registry).with(@s)
      @m.after_hook
    end

    it "invokes cosmos::set_resource" do
      @m.should_receive(:invoke).with('cosmos::set_resource', @r)
      @m.after_hook
    end
  end

  describe "#last_hook" do
    before(:each) do
      setup_manufactured

      # generate mining distance exceeded reason
      @sys = create(:solar_system)

      @sh = create(:valid_ship,
                   :location => build(:location, :coordinates => [0,0,0],
                                      :parent_id => @sys.location.id),
                   :solar_system => @sys)
      @rsh = @registry.safe_exec { |es| es.find { |e| e.id == @sh.id } }

      @r = create(:resource,
                  :entity =>
                    create(:asteroid,
                           :location => build(:location, :coordinates => [0,0,0]),
                           :solar_system => @sys))
      @rrs =
        Cosmos::RJR.registry.safe_exec { |entities|
          entities.find { |e| e.id == @r.entity.id }
        }.resources.first

      @m = Mining.new :ship => @sh, :resource => @r
      @m.registry= @registry
      @m.node = Manufactured::RJR.node
    end

    it "stops mining" do
      @sh.should_receive(:stop_mining)
      @m.last_hook
    end

    it "runs mining_stopped callbacks" do
      # generate distance exceeded reason
      @r.entity.solar_system = build(:solar_system)
      @rsh.should_receive(:run_callbacks).with('mining_stopped', @r, 'mining_distance_exceeded')
      @m.last_hook
    end

    describe "reason" do
      context "distance exceeded" do
        it "is mining_distance_exceeded" do
          @sh.location.x = @r.entity.location.x + @sh.mining_distance * 1.2
          @rsh.should_receive(:run_callbacks).
               with('mining_stopped', @r, 'mining_distance_exceeded')
          @m.last_hook
        end
      end

      context "different systems" do
        it "is mining_distance_exceeded" do
          @sh.solar_system = build(:solar_system)
          @rsh.should_receive(:run_callbacks).
               with('mining_stopped', @r, 'mining_distance_exceeded')
          @m.last_hook
        end
      end

      context "ship at max capacity" do
        it "is ship_cargo_full" do
          @sh.add_resource Cosmos::Resource.new :quantity => @sh.cargo_space
          @rsh.should_receive(:run_callbacks).
               with('mining_stopped', @r, 'ship_cargo_full')
          @m.last_hook
        end
      end

      context "ship is docked" do
        it "is ship_docked" do
          @sh.dock_at build(:station)
          @rsh.should_receive(:run_callbacks).
               with('mining_stopped', @r, 'ship_docked')
          @m.last_hook
        end
      end

      context "resource is depleted" do
        it "is resource_depleted" do
          @r.quantity = 0
          @rsh.should_receive(:run_callbacks).
               with('mining_stopped', @r, 'resource_depleted')
          @m.last_hook
        end
      end

      #context "other" do
      #  it "TODO"
      #end
    end
  end

  describe "#should_run?" do
    context "resource retrieval error has occurred" do
      it "returns false" do
        m = Mining.new
        m.instance_variable_set(:@error, true)
        m.should_run?.should be_false
      end
    end

    context "server command shouldn't run" do
      it "returns false" do
        m = Mining.new :ship => build(:ship), :resource => build(:resource),
                       :exec_rate => 1, :last_ran_at => Time.now
        m.should_run?.should be_false
      end
    end

    context "ship cannot mine resource" do
      it "returns false" do
        s = build(:ship)
        r = build(:resource)
        m = Mining.new :ship => s, :resource => r
        s.should_receive(:can_mine?).and_return(false)
        m.should_run?.should be_false
      end
    end

    context "ship cannot accept resource" do
      it "returns false" do
        s = build(:ship)
        r = build(:resource)
        m = Mining.new :ship => s, :resource => r
        s.should_receive(:can_mine?).and_return(true)
        s.should_receive(:can_accept?).and_return(false)
        m.should_run?.should be_false
      end
    end

    it "returns true" do
      s = build(:ship)
      r = build(:resource)
      m = Mining.new :ship => s, :resource => r
      s.should_receive(:can_mine?).and_return(true)
      s.should_receive(:can_accept?).and_return(true)
      m.should_run?.should be_true
    end
  end

  describe "#run!" do
    before(:each) do
      setup_manufactured

      @s = create(:valid_ship, :mining_quantity => 5)
      @r = create(:resource, :quantity => 10)
      @m = Mining.new :ship => @s, :resource => @r

      @rsh = @registry.safe_exec { |es| es.find { |e| e.id == @s.id } }

      @m.registry = @registry
      @m.node = Manufactured::RJR.node
    end

    it "invokes command.run!" do
      @m.run!
      @m.last_ran_at.should be_an_instance_of(Time)
    end

    it "removes mining quantity from resource" do
      @m.run!
      @r.quantity.should == 5
    end

    it "adds mining quantity to ship" do
      @m.run!
      @s.resources.first.id.should == @r.id
      @s.resources.first.quantity.should == 5
    end

    context "resource has < ships mining quantity" do
      it "adds remaining resource to ship" do
        @r.quantity = 4
        @m.run!
        @s.resources.first.quantity.should == 4
      end

      it "sets resource quantity to 0" do
        @r.quantity = 4
        @m.run!
        @r.quantity.should == 0
      end
    end

    context "exception after resource removed but before added" do
      it "adds resource back to entity" do
        @s.should_receive(:add_resource).and_raise(Exception)
        @m.run!
        @r.quantity.should == 10
      end
    end

    it "runs resource_collected callbacks" do
      @rsh.should_receive(:run_callbacks).
           with('resource_collected', @r, @s.mining_quantity)
      @m.run!
    end

    it "updates resources collected user attribute"
  end

  describe "#remove?" do
    before(:each) do
      @rs = build(:resource)
      @sh = build(:ship)
      @m = Mining.new :ship => @sh, :resource => @rs
    end

    context "resource retrieval error occurred" do
      it "returns true" do
        @m.instance_variable_set(:@error, true)
        @m.remove?.should be_true
      end
    end

    context "ship cannot mine resource" do
      it "returns true" do
        @sh.should_receive(:can_mine?).and_return(false)
        @m.remove?.should be_true
      end
    end

    context "ship cannot accept resource" do
      it "returns true" do
        @sh.should_receive(:can_mine?).and_return(true)
        @sh.should_receive(:can_accept?).and_return(false)
        @m.remove?.should be_true
      end
    end

    it "returns false" do
        @sh.should_receive(:can_mine?).and_return(true)
        @sh.should_receive(:can_accept?).and_return(true)
        @m.remove?.should be_false
    end
  end

  describe "#to_json" do
    it "returns mining command in json format" do
      s = build(:ship)
      r = build(:resource)
      m = Mining.new :ship => s, :resource => r

      j = m.to_json
      j.should include('"json_class":"Manufactured::Commands::Mining"')
      j.should include('"id":"'+m.id+'"')
      j.should include('"ship":{"json_class":"Manufactured::Ship"')
      j.should include('"resource":{"json_class":"Cosmos::Resource"')
    end
  end

  describe "#json_create" do
    it "returns attack command from json format" do
      j = '{"json_class":"Manufactured::Commands::Mining","data":{"ship":{"json_class":"Manufactured::Ship","data":{"id":10016,"user_id":null,"type":null,"size":null,"hp":25,"shield_level":0,"cargo_capacity":100,"attack_distance":100,"mining_distance":100,"docked_at":null,"attacking":null,"mining":null,"location":{"json_class":"Motel::Location","data":{"id":null,"x":0.0,"y":0.0,"z":1.0,"orientation_x":1.0,"orientation_y":0.0,"orientation_z":0.0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_id":null,"resources":[],"callbacks":[]}},"resource":{"json_class":"Cosmos::Resource","data":{"id":"type-name16","quantity":50,"entity_id":null}},"id":"mining-cmd-10016","exec_rate":null,"ran_first_hooks":false,"last_ran_at":null}}'
      m = JSON.parse j

      m.should be_an_instance_of(Mining)
      m.ship.should be_an_instance_of(Manufactured::Ship)
      m.resource.should be_an_instance_of(Cosmos::Resource)
    end
  end

end # describe Mining
end # module Manufactured::Commands
