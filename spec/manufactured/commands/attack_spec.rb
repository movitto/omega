# Attack Command tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/commands/attack'

module Manufactured::Commands
describe Attack, :rjr => true do
  describe "#id" do
    it "should be unique per attacker" do
      a = Attack.new
      a.attacker = build(:ship)
      a.id.should == 'attack-cmd-' + a.attacker.id.to_s
    end
  end

  describe "#processes?" do
    before(:each) do
      @a = Attack.new
      @a.attacker = build(:ship)
      @a.defender = build(:ship)
    end

    context "entity is attacker" do
      it "returns true" do
        @a.processes?(@a.attacker).should be_true
      end
    end

    context "entity is defender" do
      it "returns true" do
        @a.processes?(@a.defender).should be_true
      end
    end

    it "returns false" do
      @a.processes?(build(:ship)).should be_false
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
      setup_manufactured
      e1 = build(:ship)
      e2 = build(:ship)
      a = Attack.new :attacker => e1, :defender => e2
      a.registry= @registry
      e1.should_receive(:start_attacking).with(e2)
      a.first_hook
    end
  end

  describe "#before_hook" do
    before(:each) do
      setup_manufactured

      @e1 = create(:valid_ship)
      @e2 = create(:valid_ship)
      @a = Attack.new :attacker => @e1, :defender => @e2
      @a.registry = @registry
      @a.node = Manufactured::RJR.node
    end

    it "retrieves attacker and defender from registry" do
      @a.should_receive(:retrieve).with(@e1.id).and_call_original
      @a.should_receive(:retrieve).with(@e2.id).and_call_original
      @a.before_hook
    end

    it "updates attacker and defender locations from motel" do
      @a.should_receive(:invoke).with('motel::get_location',
                                      'with_id', @e1.location.id)
      @a.should_receive(:invoke).with('motel::get_location',
                                      'with_id', @e2.location.id)
      @a.before_hook
    end
  end

  describe "#after_hook" do
    before(:each) do
      setup_manufactured

      @e1 = create(:valid_ship)
      @e2 = create(:valid_ship)

      @a = Attack.new :attacker => @e1, :defender => @e2
      @a.registry= @registry
    end

    it "saves attacker and defender in registry" do
      @a.should_receive(:update_registry).with(@e1)
      @a.should_receive(:update_registry).with(@e2)
      @a.after_hook
    end
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

      it "sets destroyed ship's location's movement strategy to stopped" do
        @a.should_receive(:invoke).with('motel::update_location',
                                        an_instance_of(Motel::Location)) { |*args|
          args.last.id.should == @e2.location.id
          args.last.movement_strategy.should == Motel::MovementStrategies::Stopped.instance
        }
        @a.should_receive(:invoke).with(any_args).at_least(:twice)
        @a.last_hook
      end

      it "stops registry commands for destroyed ship" do
        @registry.should_receive(:stop_commands_for).with(@e2)
        @a.last_hook
      end

      it "updates ships user destroyed and user ship destroyed attributes" do
        u1 = Users::RJR.registry.proxy_for { |e| e.id == @e1.user_id }
        u2 = Users::RJR.registry.proxy_for { |e| e.id == @e2.user_id }

        enable_attributes {
          u1.attribute(Users::Attributes::ShipsUserDestroyed.id).should be_nil
          u2.attribute(Users::Attributes::UserShipsDestroyed.id).should be_nil

          @a.last_hook

          u1.attribute(Users::Attributes::ShipsUserDestroyed.id).level.should == 1
          u2.attribute(Users::Attributes::UserShipsDestroyed.id).level.should == 1
        }
      end

      it "runs destroyed callbacks" do
        @re2.should_receive(:run_callbacks).with('defended_stop', @e1)
        @re2.should_receive(:run_callbacks).with('destroyed_by', @e1)
        @a.last_hook
      end

      it "adds new entity destroyed event to registry" do
        lambda {
          @a.last_hook
        }.should change{@registry.entities.size}.by(1)
        event = @registry.entities.last
        event.should be_an_instance_of(Manufactured::Events::EntityDestroyed)
        event.entity.id.should == @a.defender.id
      end

      context "defender has cargo" do
        before(:each) do
          @r1 = build(:resource, :quantity => 50)
          @r2 = build(:resource, :quantity => 50)
          @e2.resources << @r1
          @e2.resources << @r2
        end

        it "creates loot" do
          lambda{
            @a.last_hook
          }.should change{@registry.entities.size}.by(2)

          l = @registry.entities[-2]
          l.should be_an_instance_of(Manufactured::Loot)
          l.id.should == "#{@e2.id}-loot"
          (l.location - @e2.location).should == 0
          l.system_id.should == @e2.system_id
          l.location.movement_strategy.should ==
            Motel::MovementStrategies::Stopped.instance
          l.cargo_capacity.should == @e2.cargo_capacity
          l.resources.size.should == 2
          l.resources[0].id.should == @r1.id
          l.resources[0].material_id.should == @r1.material_id
          l.resources[0].quantity.should == 50
          l.resources[0].entity_id.should == l.id
          l.resources[1].id.should == @r2.id
          l.resources[1].material_id.should == @r2.material_id
          l.resources[1].quantity.should == 50
          l.resources[1].entity_id.should == l.id
          lid = l.id
        end
      end
    end
  end

  describe "#should_run?" do
    context "server command shouldn't run" do
      it "returns false" do
        a = Attack.new :exec_rate => 1, :last_ran_at => Time.now
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
      dd = @e1.damage_dealt
      sl = @e2.shield_level
      @a.run!
      @e2.shield_level.should == sl - dd
    end

    context "shield level < damage dealt" do
      before(:each) do
        @e1.should_receive(:damage_dealt).at_least(:once).and_return(10)
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
        @e1.should_receive(:damage_dealt).at_least(:once).and_return(5)
        @e2.shield_level = 0
        @e2.hp = 4
        @a.run!
        @e2.hp.should == 0
      end
    end

    context "defender hp == 0" do
      it "sets defender destroyed by" do
        @e1.should_receive(:damage_dealt).at_least(:once).and_return(5)
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
      it "returns true" do
        e = build(:ship, :hp => 0)
        a = Attack.new :defender => e
        a.remove?.should be_true
      end
    end

    context "attacker cannot attack defender" do
      it "returns true" do
        e1 = build(:ship, :hp => 10)
        e2 = build(:ship, :hp => 10)
        e2.should_receive(:can_attack?).and_return(false)
        a = Attack.new :defender => e1, :attacker => e2
        a.remove?.should be_true
      end
    end

    it "returns false" do
      e1 = build(:ship, :hp => 10)
      e2 = build(:ship, :hp => 10)
      e2.should_receive(:can_attack?).and_return(true)
      a = Attack.new :defender => e1, :attacker => e2
      a.remove?.should be_false
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
      a = RJR::JSONParser.parse j

      a.should be_an_instance_of(Attack)
      a.attacker.should be_an_instance_of(Manufactured::Ship)
      a.defender.should be_an_instance_of(Manufactured::Ship)
    end
  end

end # describe Attack
end # module Manufactured::Commands
