# Construction Command tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/commands/shield_refresh'
require 'manufactured/commands/attack'

module Manufactured::Commands
describe ShieldRefresh do
  describe "#id" do
    it "should be unique per entity" do
      s = ShieldRefresh.new
      s.entity = build(:ship)
      s.id.should == 'shield-refresh-cmd-' + s.entity.id.to_s
    end
  end

  describe "#processes?" do
    before(:each) do
      @s = ShieldRefresh.new
      @s.entity = build(:ship)
    end

    context "entity is entity whose shield is being refreshed" do
      it "returns true" do
        @s.processes?(@s.entity).should be_true
      end
    end

    it "returns false" do
      @s.processes?(build(:ship)).should be_false
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      s = ShieldRefresh.new
      s.entity.should be_nil
      s.attack_cmd.should be_nil
    end

    it "sets attributes" do
      sh = build(:ship)
      ac = Attack.new
      s  = ShieldRefresh.new :entity => sh, :attack_cmd => ac
      s.entity.should == sh
      s.attack_cmd.should == ac
    end
  end

  describe "#before_hook" do
    it "updates entity from registry" do
      sh = build(:ship)
      s = ShieldRefresh.new :entity => sh
      s.should_receive(:retrieve).with(sh.id)
      s.before_hook
    end
  end

  describe "#after_hook" do
    it "saves entity to registry" do
      sh = build(:ship)
      s = ShieldRefresh.new :entity => sh
      s.should_receive(:update_registry).with(sh)
      s.after_hook
    end
  end

  describe "#should_run?" do
    context "server command shouldn't run" do
      it "returns false" do
        s = ShieldRefresh.new :exec_rate => 1, :last_ran_at => Time.now
        s.should_run?.should be_false
      end
    end

    context "entity destroyed" do
      it "returns false" do
        sh = build(:ship, :hp => 0)
        s = ShieldRefresh.new :entity => sh
        s.should_run?.should be_false
      end
    end

    context "shield level less than max" do
      it "returns true" do
        sh = build(:ship, :hp => 50, :shield_level => 5, :max_shield_level => 50)
        s = ShieldRefresh.new :entity => sh
        s.should_run?.should be_true
      end
    end
  end

  describe "#run!" do
    before(:each) do
      @sh = build(:ship)
      @s  = ShieldRefresh.new :entity => @sh
    end

    it "invokes command.run!" do
      @s.run!
      @s.last_ran_at.should be_an_instance_of(Time)
    end

    context "shield is less than maximum" do
      before(:each) do
        @sh.shield_level = 5
        @sh.max_shield_level = 10
        @sh.shield_refresh_rate = 1
      end

      it "increases shield level" do
        old = @sh.shield_level
        @s.run!
        @sh.shield_level.should > old
      end

      it "maxes out at maximum shield level" do
        @sh.shield_level = 9.999
        @s.instance_variable_set(:@last_ran_at, Time.now - 5)
        @s.run!
        @sh.shield_level.should == 10
      end
    end
  end

  describe "#remove" do
    context "attack command should not be removed" do
      it "returns false" do
        ac = Attack.new
        s = ShieldRefresh.new :attack_cmd => ac
        ac.should_receive(:remove?).and_return(false)
        s.remove?.should be_false
      end
    end

    context "shield not at max level" do
      it "returns false" do
        ac = Attack.new
        sh = build(:ship, :shield_level => 10, :max_shield_level => 20)
        s = ShieldRefresh.new :attack_cmd => ac, :entity => sh
        ac.should_receive(:remove?).and_return(true)
        s.remove?.should be_false
      end
    end

    it "returns true" do
      ac = Attack.new
      sh = build(:ship, :shield_level => 10, :max_shield_level => 10)
      s = ShieldRefresh.new :attack_cmd => ac, :entity => sh
      ac.should_receive(:remove?).and_return(true)
      s.remove?.should be_true
    end
  end

  describe "#to_json" do
    it "returns command in json format" do
      ac = Attack.new
      sh = build(:ship)
      s = ShieldRefresh.new :entity => sh, :attack_cmd => ac

      j = s.to_json
      j.should include('"json_class":"Manufactured::Commands::ShieldRefresh"')
      j.should include('"id":"'+s.id.to_s+'"')
      j.should include('"entity":{"json_class":"Manufactured::Ship"')
      j.should include('"attack_cmd":{"json_class":"Manufactured::Commands::Attack"')
    end
  end

  describe "#json_create" do
    it "returns command from json format" do
      j = '{"json_class":"Manufactured::Commands::ShieldRefresh","data":{"attack_cmd":{"json_class":"Manufactured::Commands::Attack","data":{"attacker":null,"defender":null,"id":"attack-cmd-","exec_rate":null,"ran_first_hooks":false,"last_ran_at":null}},"entity":{"json_class":"Manufactured::Ship","data":{"id":10008,"user_id":null,"type":null,"size":null,"hp":25,"shield_level":0,"cargo_capacity":100,"attack_distance":100,"mining_distance":100,"docked_at":null,"attacking":null,"mining":null,"location":{"json_class":"Motel::Location","data":{"id":null,"x":0.0,"y":0.0,"z":1.0,"orientation_x":1.0,"orientation_y":0.0,"orientation_z":0.0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_id":null,"resources":[],"callbacks":[]}},"id":"10008","exec_rate":null,"ran_first_hooks":false,"last_ran_at":null}}'
      c = RJR::JSONParser.parse j

      c.should be_an_instance_of(ShieldRefresh)
      c.entity.should be_an_instance_of(Manufactured::Ship)
      c.attack_cmd.should be_an_instance_of(Attack)
    end
  end

end # describe ShieldRefresh
end # module Manufactured::Commands
