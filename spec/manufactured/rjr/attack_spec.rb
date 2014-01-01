# manufactured::attack_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/attack'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#attack_entity", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :ATTACK_METHODS
    end

    context "attacker_id == defender_id" do
      it "raises ArgumentError" do
        lambda {
          @s.attack_entity 'same', 'same'
        }.should raise_error(ArgumentError)
      end
    end

    context "invalid attacker id/type" do
      it "raises DataNotFound" do
        at = create(:valid_ship)
        df = create(:valid_ship)
        st = create(:valid_station)
        lambda {
          @s.attack_entity 'invalid', df.id
        }.should raise_error(DataNotFound)
        lambda {
          @s.attack_entity st.id, df.id
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid defender id/type" do
      it "raises DataNotFound" do
        at = create(:valid_ship)
        df = create(:valid_ship)
        st = create(:valid_station)
        lambda {
          @s.attack_entity at.id, 'invalid'
        }.should raise_error(DataNotFound)
        lambda {
          @s.attack_entity at.id, st.id
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-attacker)" do
      it "raise PermissionError" do
        at = create(:valid_ship)
        df = create(:valid_ship)
        lambda {
          @s.attack_entity at.id, df.id
        }.should raise_error(PermissionError)
      end
    end

    context "insufficient permissions (view-defender)" do
      it "raise PermissionError" do
        at = create(:valid_ship)
        df = create(:valid_ship)
        add_privilege @login_role, 'modify', "manufactured_entity-#{at.id}"
        lambda {
          @s.attack_entity at.id, df.id
        }.should raise_error(PermissionError)
      end
    end

    context "suffiecient permissions (modify-attacker & view-defender)" do
      before(:each) do
        @at = create(:valid_ship)
        @df = create(:valid_ship)
        add_privilege @login_role, 'modify', "manufactured_entity-#{@at.id}"
        add_privilege @login_role, 'view', "manufactured_entity-#{@df.id}"
      end

      it "does not raise PermissionError" do
        lambda {
          @s.attack_entity @at.id, @df.id
        }.should_not raise_error
      end

      it "creates new attack command" do
        lambda {
          @s.attack_entity @at.id, @df.id
        }.should change{@registry.entities.size}.by(2)
        @registry.entities[-2].should be_an_instance_of(Commands::Attack)
        @registry.entities[-2].attacker.id.should == @at.id
        @registry.entities[-2].defender.id.should == @df.id
      end

      it "creates new shield refresh command" do
        @s.attack_entity @at.id, @df.id
        @registry.entities[-1].should be_an_instance_of(Commands::ShieldRefresh)
        @registry.entities[-1].entity.id.should == @df.id
        @registry.entities[-1].attack_cmd.id.should == @registry.entities[-2].id
      end

      it "returns [attacker,defender]" do
        r = @s.attack_entity @at.id, @df.id
        r.size.should == 2
        r.first.should be_an_instance_of(Ship)
        r.first.id.should == @at.id

        r.last.should be_an_instance_of(Ship)
        r.last.id.should == @df.id
      end
    end

  end # describe #attack_entity

  describe "#dispatch_manufactured_rjr_attack" do
    it "adds manufactured::attack_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_attack(d)
      d.handlers.keys.should include("manufactured::attack_entity")
    end
  end

end #module Manufactured::RJR
