# ship module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/ship'
require 'motel/movement_strategies/linear'
require 'omega/server/callback'

module Manufactured
describe Ship do
  describe "#type-" do
    it "sets type" do
      s = Ship.new
      s.type = :frigate
      s.type.should == :frigate
    end

    it "converts type" do
      s = Ship.new
      s.type = 'frigate'
      s.type.should == :frigate
    end

    it "does not convert invalid type" do
      s = Ship.new
      s.type = 'foobar'
      s.type.should == nil
    end

    it "sets size" do
      s = Ship.new
      s.type = :frigate
      s.size.should == Ship::SIZES[:frigate]
    end
  end

  describe "#run_callbacks" do
    before(:each) do
      @cb1 = Omega::Server::Callback.new :event_type => :movement
      @cb2 = Omega::Server::Callback.new :event_type => :movement
      @cb3 = Omega::Server::Callback.new :event_type => :rotation
      @s = Ship.new :callbacks => [@cb1, @cb2, @cb3]
    end

    it "runs each callback of the specified type" do
      @cb1.should_receive(:invoke).with(@s, 42)
      @cb2.should_receive(:invoke).with(@s, 42)
      @cb3.should_not_receive(:invoke)
      @s.run_callbacks :movement, 42
    end
  end

  describe "#remove_callbacks" do
    before(:each) do
      @cb1 = Omega::Server::Callback.new :event_type  => :movement,
                                         :endpoint_id => 'node1'
      @cb2 = Omega::Server::Callback.new :event_type  => :movement,
                                         :endpoint_id => 'node2'
      @cb3 = Omega::Server::Callback.new :event_type  => :rotation,
                                         :endpoint_id => 'node1'
      @s = Ship.new :callbacks => [@cb1, @cb2, @cb3]
    end

    it "removes callbacks corresponding to the specified event type" do
      @s.remove_callbacks :event_type => :movement
      @s.callbacks.size.should == 1
      @s.callbacks.first.should == @cb3
    end

    it "removes callbacks corresponding to the specified endpoint id" do
      @s.remove_callbacks :endpoint_id => 'node1'
      @s.callbacks.size.should == 1
      @s.callbacks.first.should == @cb2
    end

    it "removes callbacks corresponding to the specified event/endpoint" do
      @s.remove_callbacks :event_type => :movement, :endpoint_id => 'node1'
      @s.callbacks.size.should == 2
      @s.callbacks[0].should == @cb2
      @s.callbacks[1].should == @cb3
    end
  end

  describe "#docked_at_id" do
    it "returns id of station ship is docked at" do
      st = Station.new :id => 42
      Ship.new(:docked_at => st).docked_at_id.should == st.id
    end

    context "ship is not docked at a station" do
      it "returns null" do
        Ship.new.docked_at_id.should == nil
      end
    end
  end

  describe "#initialize" do
    it "sets defaults" do
      s = Ship.new
      s.id.should be_nil
      s.user_id.should be_nil
      s.type.should be_nil
      s.callbacks.should == []
      s.resources.should == []
      s.docked_at.should be_nil
      s.attacking.should be_nil
      s.mining.should be_nil
      s.solar_system.should be_nil
      s.system_id.should be_nil
      s.cargo_capacity.should == 100
      s.transfer_distance.should == 200
      s.collection_distance.should == 300
      s.shield_level.should == 0

      s.location.should be_an_instance_of(Motel::Location)
      s.location.coordinates.should == [0,0,1]
      s.location.orientation.should == [1,0,0]
    end

    it "sets attributes" do
      r = build(:resource)
      d = build(:station)
      a = build(:ship)
      m = build(:ship)
      sys = build(:solar_system)
      l = build(:location)
      s = Ship.new :id                  => 'ship1',
                   :user_id             => 'user1',
                   :type                => 'frigate',
                   :callbacks           => [ :foo , :bar ],
                   :resources           => [r],
                   :docked_at           =>   d,
                   :attacking           =>   a,
                   :mining              =>   m,
                   :solar_system        => sys,
                   :location            =>   l,
                   :cargo_capacity      => 500,
                   :transfer_distance   => 100,
                   :collection_distance => 200,
                   :shield_level        => 50

      s.id.should == 'ship1'
      s.user_id.should == 'user1'
      s.type.should == :frigate
      s.callbacks.should == [:foo, :bar]
      s.resources.should == [r]
      s.docked_at.should == d
      s.attacking.should == a
      s.mining.should == m
      s.solar_system.should == sys
      s.system_id.should == sys.id
      s.location.should == l
      s.cargo_capacity.should == 500
      s.transfer_distance.should == 100
      s.collection_distance.should == 200
      s.shield_level.should == 50
    end

    context "location orientation specified" do
      it "orients location" do
        s = Ship.new :location => Motel::Location.new
        s.location.orientation.should == [0,0,1]
      end
    end

    context "movement strategy specified" do
      it "sets movement strategy on location" do
        ms = Motel::MovementStrategies::Linear.new
        s = Ship.new :movement_strategy => ms
        s.location.movement_strategy.should == ms
      end
    end

    it "sets type based attributes" do
      Ship.should_receive(:base_hp).with(:corvette).and_return(50)
      Ship.should_receive(:base_hp).with(:mining).and_return(100)
      s1 = Ship.new :type => :corvette
      s2 = Ship.new :type => :mining
      s1.hp.should == 50
      s2.hp.should == 100
      # TODO test other type based attrs
    end
  end

  describe "#update" do
    it "updates ship hp" do
      sh = Ship.new
      sh.update Ship.new(:hp => 50)
      sh.hp.should == 50
    end

    it "updates ship shield level" do
      sh = Ship.new
      sh.update Ship.new(:shield_level => 50)
      sh.shield_level.should == 50
    end

    it "updates ship distance moved" do
      sh = Ship.new
      sh1 = Ship.new
      sh1.distance_moved = 50
      sh.update sh1
      sh.distance_moved.should == 50
    end

    it "updates ship resources" do
      sh = Ship.new
      sh.update Ship.new(:resources => [42])
      sh.resources.should == [42]
    end

    it "updates ship solar system" do
      sh = Ship.new
      sys = build(:solar_system)
      sh.update Ship.new(:solar_system => sys)
      sh.solar_system.should == sys
    end

    it "updates ship location" do
      sh = Ship.new
      l = build(:location)
      sh.update Ship.new(:location => l)
      sh.location.should == l
    end

    it "updates ship mining target" do
      sh = Ship.new
      sh.update Ship.new(:mining => 42)
      sh.mining.should == 42
    end

    it "updates ship attack target" do
      sh = Ship.new
      tgt = Ship.new :id => 'tgt'
      sh.update Ship.new(:attacking => tgt)
      sh.attacking.should == tgt
      sh.attacking_id.should == 'tgt'
    end

    it "updates ship docked_at" do
      st = Station.new
      sh = Ship.new
      sh.update Ship.new(:docked_at => st)
      sh.docked_at.should == st
    end

    it "ignores other properties" do
      sh = Ship.new
      sh.update Ship.new(:max_shield_level => 42)
      sh.max_shield_level.should_not == 42
    end
  end

  describe "#valid?" do
    before(:each) do
      @sys = build(:solar_system)
      @s   = Ship.new :id           => 'ship1',
                      :user_id      => 'tu',
                      :solar_system => @sys,
                      :type         => :frigate
    end

    it "returns true" do
      @s.should be_valid
    end

    context "id is invalid" do
      it "returns false" do
        @s.id = nil
        @s.should_not be_valid
      end
    end

    context "location is invalid" do
      it "returns false" do
        @s.location = nil
        @s.should_not be_valid
      end
    end

    context "system id is invalid" do
      it "returns false" do
        @s.system_id = nil
        @s.should_not be_valid
      end
    end

    context "solar system is invalid" do
      it "returns false" do
        @s.solar_system = Ship.new
        @s.should_not be_valid
      end
    end

    context "user_id is invalid" do
      it "returns false" do
        @s.user_id = nil
        @s.should_not be_valid
      end
    end

    context "type is invalid" do
      it "returns false" do
        @s.type = 'fooz'
        @s.should_not be_valid

        @s.type = nil
        @s.should_not be_valid
      end
    end

    context "type is invalid" do
      it "returns false" do
        @s.type = nil
        @s.should_not be_valid
      end
    end

    context "size is invalid" do
      it "returns false" do
        @s.size = 512
        @s.should_not be_valid
      end
    end

    context "docked_at is invalid" do
      it "returns false" do
        @s.dock_at(build(:ship))
        @s.should_not be_valid

        st = build(:station,
                   :location => build(:location,
                                      :parent => @sys.location))
        @s.dock_at(st)
        @s.location.x = st.location.x + st.docking_distance * 2
        @s.should_not be_valid
      end
    end

    context "mining is invalid" do
      it "returns false" do
        @s.start_mining(false)
        @s.should_not be_valid

        ast = build(:asteroid,
                    :location => build(:location,
                                       :parent => @sys.location))
        ast.set_resource(build(:resource))
        @s.start_mining(ast.resources.first)
        ast.location.x = ast.location.x + @s.mining_distance * 2
        @s.should_not be_valid
      end
    end

    context "attacking is invalid" do
      it "returns false" do
        @s.type = :corvette
        @s.start_attacking(build(:station))
        @s.should_not be_valid

        sh = build(:ship,
                   :location => build(:location,
                                      :parent => @sys.location))
        @s.start_attacking(sh)
        @s.location.x = sh.location.x + @s.attack_distance * 2
        @s.should_not be_valid
      end
    end

    context "callbacks are is invalid" do
      it "returns false" do
        @s = Ship.new :callbacks => [nil]
        @s.should_not be_valid
      end
    end

    context "resources are invalid" do
      it "returns false" do
        @s.resources = ['false']
        @s.should_not be_valid
      end
    end

    context "shield level is invalid" do
      it "returns false" do
        @s.shield_level = 25
        @s.should_not be_valid
      end
    end
  end

  describe "#alive?" do
    context "hp <= 0" do
      it "returns false" do
        s = Ship.new :hp => 0
        s.should_not be_alive

        s = Ship.new :hp => -10
        s.should_not be_alive
      end
    end

    it 'returns true' do
      s = Ship.new :hp => 10
      s.should be_alive
    end
  end

  describe "#can_dock_at?" do
    before(:each) do
      @s  = build(:solar_system)
      @s1 = build(:solar_system)
      @sh = Manufactured::Ship.new :id => 'ship1'
      @st = Manufactured::Station.new :id => 'station1'

      @s.location.coordinates = [0, 0, 0]
      @s1.location.coordinates = [0, 0, 1]
      @sh.location.parent = @s1.location
      @st.location.parent = @s1.location
    end

    context "ship/station in different systems" do
      it "returns false" do
        @sh.location.parent = @s.location
        @sh.can_dock_at?(@st).should be_false
      end
    end

    context "ship/station too far away" do
      it "returns false" do
        @sh.location.x = 500
        @sh.can_dock_at?(@st).should be_false
      end
    end

    context "ship/station not alive" do
      it "returns false" do
        @sh.hp = 0
        @sh.can_dock_at?(@st).should be_false
      end
    end

    it "returns true" do
      @sh.can_dock_at?(@st).should be_true
    end
  end

  describe "#can_attack?" do
    before(:each) do
      @s1  = build(:solar_system)
      @s2  = build(:solar_system)
      @sh1 = Ship.new :id => 'ship1', :solar_system => @s1,
                      :type => :corvette, :user_id => 'bob'
      @sh2 = Ship.new :id => 'ship1', :solar_system => @s1,
                      :user_id => 'jim'

      @sh1.location.coordinates = [0, 0, 0]
      @sh2.location.coordinates = [0, 0, 1]
    end

    context "not attack ship" do
      it "returns false" do
        @sh1.type = :mining
        @sh1.can_attack?(@sh2).should be_false
      end
    end

    context "ships in different systems" do
      it "returns false" do
        @sh1.location.parent = @s2.location
        @sh1.can_attack?(@sh2).should be_false
      end
    end

    context "ships too far away" do
      it "returns false" do
        @sh1.location.x = 500
        @sh1.can_attack?(@sh2).should be_false
      end
    end

    context "ships not alive" do
      it "returns false" do
        @sh1.hp = 0
        @sh1.can_attack?(@sh2).should be_false
      end
    end

    it "returns true" do
      @sh1.can_attack?(@sh2).should be_true
    end

  end

  describe "#can_mine?" do
    before(:each) do
      @s1  = build(:solar_system)
      @s2  = build(:solar_system)

      @sh = Ship.new :id => 'ship1', :solar_system => @s1, :type => :mining
      @a  = build(:asteroid, :solar_system => @s1)
      @r  = Cosmos::Resource.new :entity => @a, :id => 'metal-steel', :quantity => 500

      @q = @sh.cargo_space

      @sh.location.coordinates = [0, 0, 0]
      @a.location.coordinates = [0, 0, 1]
    end

    context "not mining ship" do
      it "returns false" do
        @sh.type = :corvette
        @sh.can_mine?(@r, @q).should be_false
      end
    end

    context "ship docked" do
      it "returns false" do
        @sh.should_receive(:docked?).and_return(true)
        @sh.can_mine?(@r, @q).should be_false
      end
    end

    context "ship not alive" do
      it "returns false" do
        @sh.should_receive(:alive?).and_return(false)
        @sh.can_mine?(@r, @q).should be_false
      end
    end

    context "ships/resource in different systems" do
      it "returns false" do
        @sh.location.parent = @s2.location
        @sh.can_mine?(@r, @q).should be_false
      end
    end

    context "ship/resource too far away" do
      it "returns false" do
        @sh.location.x = 5000
        @sh.can_mine?(@r, @q).should be_false
      end
    end

    context "cargo capacity would be exceeded" do
      it "returns false" do
        @sh.add_resource(build(:resource, :quantity => @sh.cargo_capacity))
        @sh.can_mine?(@r, @q).should be_false
      end
    end

    it "returns true" do
      @sh.can_mine?(@r, @q).should be_true
    end
  end

  describe "#docked?" do
    before(:each) do
      @sh = Manufactured::Ship.new :id => 'ship1'
      @st = Manufactured::Station.new :id => 'station1'
    end

    context "ship is docked" do
      it "returns true" do
        @sh.dock_at(@st)
        @sh.should be_docked
      end
    end

    context "ship is not docked" do
      it "returns false" do
        @sh.should_not be_docked
      end
    end
  end

  describe "#docked" do
    it "sets docked station" do
      sh = Manufactured::Ship.new :id => 'ship1'
      st = Manufactured::Station.new :id => 'station1'
      sh.dock_at(st)
      sh.docked_at.should == st
    end
  end

  describe "#undock" do
    it "clears docked station" do
      sh = Manufactured::Ship.new :id => 'ship1'
      st = Manufactured::Station.new :id => 'station1'
      sh.dock_at(st)
      sh.undock
      sh.docked_at.should be_nil
    end
  end

  describe "#attacking?" do
    before(:each) do
      @s1   = Ship.new :id => 'ship1'
      @s2   = Ship.new :id => 'ship2'
    end

    context "ship is attacking" do
      it 'returns true' do
        @s1.start_attacking(@s2)
        @s1.should be_attacking
      end
    end

    context "ship is not attacking" do
      it 'returns false' do
        @s1.should_not be_attacking
        @s1.attacking.should be_nil
      end
    end
  end

  describe "#start_attacking" do
    it "sets attacking target" do
      s1   = Ship.new :id => 'ship1'
      s2   = Ship.new :id => 'ship2'
      s1.start_attacking(s2)
      s1.attacking.should == s2
    end
  end

  describe "#stop_attacking" do
    it "clears attacking target" do
      s1   = Ship.new :id => 'ship1'
      s2   = Ship.new :id => 'ship2'
      s1.start_attacking(s2)
      s1.stop_attacking
      s1.attacking.should be_nil
    end
  end

  describe "#mining?" do
    before(:each) do
      @s = Manufactured::Ship.new :id => 'ship1'
      @r = Cosmos::Resource.new :id => 'metal-titanium'
    end

    context "ship is mining" do
      it 'returns true' do
        @s.start_mining(@r)
        @s.should be_mining
      end
    end

    context "ship is not mining" do
      it 'returns false' do
        @s.should_not be_mining
      end
    end
  end

  describe "#start_mining" do
    it "sets mining target" do
      s = Manufactured::Ship.new :id => 'ship1'
      r = Cosmos::Resource.new :id => 'metal-titanium'
      s.start_mining(r)
      s.mining.should == r
    end
  end

  describe "#stop_mining" do
    it "clears mining target" do
      s = Manufactured::Ship.new :id => 'ship1'
      r = Cosmos::Resource.new :id => 'metal-titanium'
      s.start_mining(r)
      s.stop_mining
      s.should_not be_mining
    end
  end

  describe "#to_json" do
    it "returns ship in json format" do
      sys = build(:solar_system)
      location= Motel::Location.new :id => 20, :y => -15
      s = Manufactured::Ship.new(:id => 'ship42', :user_id => 420,
                                 :type => :frigate,
                                 :hp   => 500, :shield_level => 20,
                                 :solar_system => sys,
                                 :location => location)

      station = Manufactured::Station.new :id => 'station42'
      s.dock_at(station)

      res = Cosmos::Resource.new(:id => 'res1')
      s.start_mining(res)

      s2 = Manufactured::Ship.new :id => 'ship52'
      s.start_attacking(s2)


      j = s.to_json
      j.should include('"json_class":"Manufactured::Ship"')
      j.should include('"id":"ship42"')
      j.should include('"user_id":420')
      j.should include('"type":"frigate"')
      j.should include('"size":35')
      j.should include('"hp":500')
      j.should include('"shield_level":20')
      j.should include('"docked_at_id":"station42"')
      j.should include('"json_class":"Cosmos::Resource"')
      j.should include('"id":"res1"')
      j.should include('"json_class":"Manufactured::Ship"')
      j.should include('"attacking_id":"ship52"')
      j.should include('"json_class":"Motel::Location"')
      j.should include('"id":20')
      j.should include('"y":-15')
      j.should include('"system_id":"'+sys.id+'"')
    end
  end

  describe "#json_create" do
    it "returns ship from json format" do
      j = '{"json_class":"Manufactured::Ship","data":{"id":"ship42","user_id":420,"type":"frigate","size":35,"hp":500,"shield_level":20,"cargo_capacity":100,"attack_distance":100,"mining_distance":100,"docked_at":{"json_class":"Manufactured::Station","data":{"id":"station42","user_id":null,"type":"offense","size":35,"errors":{},"docking_distance":200,"location":{"json_class":"Motel::Location","data":{"id":null,"x":0,"y":0,"z":0,"orientation_x":null,"orientation_y":null,"orientation_z":null,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_name":null,"resources":{}}},"attacking":{"json_class":"Manufactured::Ship","data":{"id":"ship52","user_id":null,"type":null,"size":null,"hp":25,"shield_level":0,"cargo_capacity":100,"attack_distance":100,"mining_distance":100,"docked_at":null,"attacking":null,"mining":null,"location":{"json_class":"Motel::Location","data":{"id":null,"x":1.0,"y":0.0,"z":1.0,"orientation_x":1.0,"orientation_y":0.0,"orientation_z":0.0,"restrict_view":true,"restrict_modify":true,"parent_id":null,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_id":null,"resources":[],"callbacks":[]}},"mining":{"json_class":"Cosmos::Resource","data":{"id":"res1","quantity":0,"entity_id":null}},"location":{"json_class":"Motel::Location","data":{"id":20,"x":null,"y":-15.0,"z":null,"orientation_x":null,"orientation_y":null,"orientation_z":null,"restrict_view":true,"restrict_modify":true,"parent_id":10000,"children":[],"movement_strategy":{"json_class":"Motel::MovementStrategies::Stopped","data":{"step_delay":1}},"callbacks":{},"last_moved_at":null}},"system_id":"system1","resources":[]}}'
      s = ::RJR.parse_json(j)

      s.class.should == Manufactured::Ship
      s.id.should == "ship42"
      s.user_id.should == 420
      s.type.should == :frigate
      s.size.should == Ship::SIZES[:frigate]
      s.hp.should == 500
      s.shield_level.should == 20
      s.location.should_not be_nil
      s.location.y.should == -15
      s.system_id.should == 'system1'
    end
  end

end # describe Ship
end # module Manufactured
