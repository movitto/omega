# manufactured::create_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/create'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#create_entity", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured  :CREATE_METHODS
    end

    def build_ship
      sys = create(:solar_system)
      s = build(:valid_ship)
      s.user_id = @login_user.id
      s.solar_system = sys
      s
    end

    context "insufficient privileges (create-manufactured_entities)" do
      it "raises PermissionError" do
        s = build_ship
        lambda {
          @s.create_entity(s)
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (create-manufactured_entities)" do
      before(:each) do
        add_privilege(@login_role, 'create', 'manufactured_entities')
      end

      it "does not raise PermissionError" do
        s = build_ship
        lambda {
          @s.create_entity(s)
        }.should_not raise_error
      end

      context "invalid entity type specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_entity(42)
          }.should raise_error(ValidationError)
        end
      end

      context "invalid system specified" do
        it "raises DataNotFound" do
          sys1 = build(:solar_system)
          s = build_ship
          s.solar_system = sys1
          lambda {
            @s.create_entity(s)
          }.should raise_error(DataNotFound)
        end
      end

      context "invalid user specified" do
        it "raises DataNotFound" do
          u1 = build(:user)
          s = build_ship
          s.user_id = u1.id
          lambda {
            @s.create_entity(s)
          }.should raise_error(DataNotFound)
        end
      end

      context "user has maximum number of entities" do
        it "raises PermissionError" do
          enable_attributes {
            s = build_ship

            attr = Users::Attributes::EntityManagementLevel
            Users::RJR.registry.safe_exec { |entities|
              entities.find(&with_id(s.user_id)).attribute(attr.id).level = 0
            }

            lambda {
              @s.create_entity(s)
            }.should raise_error(PermissionError)
          }
        end
      end

      [[:movement_speed,   Users::Attributes::PilotLevel.id   ],
       [:damage_dealt,     Users::Attributes::OffenseLevel.id ],
       [:max_shield_level, Users::Attributes::DefenseLevel.id ],
       [:mining_quantity,  Users::Attributes::MiningLevel.id  ]].each { |p,a|
         it "adjusts entity.#{p} from user attribute #{a}"
       }

      it "adds resource to stations"

      context "location could not be added to motel" do
        before(:each) do
          os  = create(:valid_ship, :hp => 10)
          @sh = build_ship
          # create_entity will set location id's the same
          @sh.id = os.id
          @sh.hp = 5
        end

        it "raises OperationError" do
          lambda {
            @s.create_entity(@sh)
          }.should raise_error(OperationError)
        end

        it "does not add entity" do
          lambda {
            lambda{
              @s.create_entity(@sh)
            }.should raise_error(OperationError)
          }.should_not change{@registry.entities.size}
          @registry.entity(&with_id(@sh.id)).hp.should == 10
        end
      end

      context "entity could not be added to registry" do
        before(:each) do
          os  = create(:valid_ship)
          @sh = build_ship
          # invalid entity:
          @sh.max_shield_level = 5 ; @sh.shield_level = 10
        end

        it "raises OperationError" do
          lambda {
            @s.create_entity(@sh)
          }.should raise_error(OperationError)
        end

        it "deletes motel location" do
          @s.node.should_receive(:invoke).
                  with("motel::delete_location", @sh.id).and_call_original # XXX assuming loc.id == sh.id
          @s.node.should_receive(:invoke).at_least(:once).and_call_original
          begin
            @s.create_entity(@sh)
          rescue OperationError
          end

          Motel::RJR.registry.entity(&with_id(@sh.id))
        end
      end

      it "creates new entity in registry" do
        s = build_ship
        lambda {
          @s.create_entity(s)
        }.should change{@registry.entities.size}.by(1)
        @registry.entity(&with_id(s.id)).should_not be_nil
      end

      it "creates new location in motel" do
        s = build_ship
        lambda {
          @s.create_entity(s)
        }.should change{Motel::RJR.registry.entities.size}.by(1)
        Motel::RJR.registry.entity(&with_id(s.location.id)).should_not be_nil
      end

      it "grants view/modify on entity to owner's role" do
        s = build_ship
        eid = "manufactured_entity-#{s.id}"
        @s.node.should_receive(:invoke).
                with("users::add_privilege",
                     "user_role_#{@login_user.id}",
                     "view", eid).and_call_original
        @s.node.should_receive(:invoke).
                with("users::add_privilege",
                     "user_role_#{@login_user.id}",
                     "modify", eid).and_call_original
        @s.node.should_receive(:invoke).
                at_least(2).times.and_call_original # for other calls to node.invoke
        @s.create_entity(s)
        Users::RJR.registry.entity{ |e| e.id == @login_user.id }.
                            has_privilege_on?('view', eid).should be_true
        Users::RJR.registry.entity{ |e| e.id == @login_user.id }.
                            has_privilege_on?('modify', eid).should be_true
      end

      it "grants view on entity's location to owner's role" do
        s = build_ship
        @s.node.should_receive(:invoke).
                with("users::add_privilege",
                     "user_role_#{@login_user.id}",
                     "view", "location-#{s.id}").and_call_original
        @s.node.should_receive(:invoke).
                at_least(1).times.and_call_original # for other calls to node.invoke
        @s.create_entity(s)
        Users::RJR.registry.entity{ |e| e.id == @login_user.id }.
                            has_privilege_on?('view', "location-#{s.id}").should be_true
      end

      it "returns entity" do
        s = build_ship
        r = @s.create_entity(s)
        r.should be_an_instance_of(Ship)
        r.id.should == s.id
      end
    end
  end # describe "#create_entity"

  describe "#dispatch_manufactured_rjr_create" do
    it "adds manufactured::create_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_create(d)
      d.handlers.keys.should include("manufactured::create_entity")
    end
  end
end #module Manufactured::RJR
