# Attack Command tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/commands/attack'

module Manufactured::Commands
describe Attack do
  describe "#id" do
    it "should be unique per attacker" do
      a = Attack.new
      a.attacker = build(:ship)
      a.id.should == 'attack-cmd-' + a.attacker.id.to_s
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      a = Attack.new
      a.attacker.should be_nil
      a.defender.should be_nil
    end

    it "sets attributes" do
      e1 = build(:ship)
      e2 = build(:ship)
      a = Attack.new :attacker => e1, :defender => e2
      a.attacker.should == e1
      a.defender.should == e2
    end
  end

  describe "#first_hook" do
    it "starts attack" do
      e1 = build(:ship)
      e2 = build(:ship)
      a = Attack.new :attacker => e1, :defender => e2
      e1.should_receive(:start_attacking).with(e2)
      a.first_hook
    end
  end

  describe "#before_hook" do
    it "retrieves attacker from registry"
    it "retrieves defender from registry"
  end

  describe "#after_hook" do
    it "saves attacker in registry"
    it "saves defender in registry"
  end

  describe "#last_hook" do
    before(:each) do
      setup_manufactured

      @e1 = create(:valid_ship)
      @e2 = create(:valid_ship)

      @re1 = @registry.safe_exec { |es| es.find { |e| e.id == @e1.id } }
      @re2 = @registry.safe_exec { |es| es.find { |e| e.id == @e2.id } }

      @a = Attack.new :attacker => @e1, :defender => @e2
      @a.registry= @registry
      @a.node = Manufactured::RJR.node
    end

    it "stops attacking" do
      @e1.should_receive(:stop_attacking)
      @a.last_hook
    end

    it "runs attacked_stop callbacks" do
      @re1.should_receive(:run_callbacks).with('attacked_stop', @e2)
      @a.last_hook
    end

    it "runs defended stop callbacks" do
      @re2.should_receive(:run_callbacks).with('defended_stop', @e1)
      @a.last_hook
    end

    context "defender hp == 0" do
      before(:each) do
        @e2.hp = 0
      end

      it "runs destroyed callbacks" do
        @re2.should_receive(:run_callbacks).with('defended_stop', @e1)
        @re2.should_receive(:run_callbacks).with('destroyed_by', @e1)
        @a.last_hook
      end

      context "defender has cargo" do
        before(:each) do
          @e2.resources << build(:resource, :quantity => 50)
        end

        it "creates loot"
      end
    end
  end

  describe "#should_run?" do
    context "server command shouldn't run" do
      it "returns false" do
        a = Attack.new
        a.terminate!
        a.should_run?.should be_false
      end
    end

    context "attacker cannot attack defender" do
      it "returns false" do
        e1 = build(:ship)
        e2 = build(:ship)
        a = Attack.new :attacker => e1, :defender => e2
        e1.should_receive(:can_attack?).with(e2).and_return(false)
        a.should_run?.should be_false
      end
    end

    it "returns true" do
      e1 = build(:ship)
      e2 = build(:ship)
      a = Attack.new :attacker => e1, :defender => e2
      e1.should_receive(:can_attack?).with(e2).and_return(true)
      a.should_run?.should be_true
    end
  end

  describe "#run!" do
    before(:each) do
      setup_manufactured

      @e1 = create(:valid_ship)
      @e2 = create(:valid_ship)

      @re1 = @registry.safe_exec { |es| es.find { |e| e.id == @e1.id } }
      @re2 = @registry.safe_exec { |es| es.find { |e| e.id == @e2.id } }

      @a = Attack.new :attacker => @e1, :defender => @e2
      @a.registry= @registry
      @a.node = Manufactured::RJR.node
    end

    it "invokes command.run!" do
      @a.run!
      @a.last_ran_at.should be_an_instance_of(Time)
    end

    it "reduces defender shield level" do
      @e1.damage_dealt = 5
      @e2.shield_level = 10
      @a.run!
      @e2.shield_level.should == 5
    end

    context "shield level < damage dealt" do
      before(:each) do
        @e1.damage_dealt = 10
        @e2.shield_level = 5
        @e2.hp = 10
      end

      it "sets shield level to 0" do
        @a.run!
        @e2.shield_level.should == 0
      end

      it "reduces defender hp" do
        @a.run!
        @e2.hp.should == 5
      end
    end

    context "defender hp < 0" do
      it "sets defender hp 0" do
        @e1.damage_dealt = 5
        @e2.shield_level = 0
        @e2.hp = 4
        @a.run!
        @e2.hp.should == 0
      end
    end

    context "defender hp == 0" do
      it "sets defender destroyed by" do
        @e1.damage_dealt = 5
        @e2.shield_level = 0
        @e2.hp = 4
        @a.run!
        @e2.destroyed_by.should == @e1
      end
    end

    it "runs attacked callbacks" do
      @re1.should_receive(:run_callbacks).with('attacked', @e2)
      @a.run!
    end

    it "runs defended callbacks" do
      @re2.should_receive(:run_callbacks).with('defended', @e1)
      @a.run!
    end
  end

  describe "#remove" do
    context "defender's hp == 0" do
      it "returns true"
    end

    context "defender's hp != 0" do
      it "returns false"
    end
  end

  describe "#to_json" do
    it "returns attack command in json format" do
      e1 = build(:ship)
      e2 = build(:ship)
      a = Attack.new :attacker => e1, :defender => e2

      j = a.to_json
      j.should include('"json_class":"Manufactured::Commands::Attack"')
      j.should include('"id":"'+a.id+'"')
      j.should include('"attacker":{"json_class":"Manufactured::Ship"')
      j.should include('"defender":{"json_class":"Manufactured::Ship"')
    end
  end

  describe "#json_create" do
    it "returns attack command from json format" do
      j = '{"json_class":"Manufactured::Commands::Attack","data":{"attacker":{"json_class":"Manufactured::Ship","data":{"id":10033,"user_id":null,"type":null,"size":null,"hp":25,"shield_level":0,"cargo_capacity":100,"attack_distance":100,"mining_distance":100,"docked_at":null,"attacking":null,"mining":null,"location":{"json_class":"Motel::Location","data":{"id":null,"x":0.0,"y":0.0,"z":1.0,"orientation_x":1.0,"orientation_y":0.0,"orientation_z":0.0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_id":null,"resources":[],"callbacks":[]}},"defender":{"json_class":"Manufactured::Ship","data":{"id":10034,"user_id":null,"type":null,"size":null,"hp":25,"shield_level":0,"cargo_capacity":100,"attack_distance":100,"mining_distance":100,"docked_at":null,"attacking":null,"mining":null,"location":{"json_class":"Motel::Location","data":{"id":null,"x":0.0,"y":0.0,"z":1.0,"orientation_x":1.0,"orientation_y":0.0,"orientation_z":0.0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_id":null,"resources":[],"callbacks":[]}},"id":"attack-cmd-10033","exec_rate":null,"ran_first_hooks":false,"last_ran_at":null,"terminate":false}}'
      a = JSON.parse j

      a.should be_an_instance_of(Attack)
      a.attacker.should be_an_instance_of(Manufactured::Ship)
      a.defender.should be_an_instance_of(Manufactured::Ship)
    end
  end

end # describe Attack
end # module Manufactured::Commands
