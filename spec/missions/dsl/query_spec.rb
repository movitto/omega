# Missions DSL Query Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/query'

module Missions
module DSL
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

end # module DSL
end # module Missions
