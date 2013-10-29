# cosmos::get_entities tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/get'
require 'rjr/dispatcher'

module Cosmos::RJR
  describe "#get_entities" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    it "returns list of all entities" do
      # grant user permissions to view all entitys
      add_privilege @login_role, 'view', 'cosmos_entities'

      create(:galaxy)
      create(:galaxy)
      n = Cosmos::RJR.registry.entities.size
      i = Cosmos::RJR.registry.entities.collect { |e| e.id }
      s = @s.get_entities
      s.size.should == n
      s.collect { |e| e.id }.should == i
    end

    it "updates all entities and children with motel location (recursively)" do
      add_privilege @login_role, 'view', 'cosmos_entities'
      g = create(:galaxy)
      s = create(:solar_system, :parent => g)
      p = create(:planet, :parent => s)

      @s.node.should_receive(:invoke).
         with('motel::get_location', 'with_id', g.id).and_call_original
      @s.node.should_receive(:invoke).
         with('motel::get_location', 'with_id', s.id).and_call_original
      @s.node.should_receive(:invoke).
         with('motel::get_location', 'with_id', p.id).and_call_original
      @s.node.should_receive(:invoke).at_least(:once).and_call_original
      s = @s.get_entities
    end

    context "entity id/name/location specified" do
      context "entity not found" do
        it "raises DataNotFound" do
          lambda {
            @s.get_entities 'with_id', 'nonexistant'
          }.should raise_error(DataNotFound)
        end
      end

      context "user does not have view privilege on entity" do
        it "raises PermissionError" do
          g = create(:galaxy)
          lambda {
            @s.get_entities 'with_id', g.id
          }.should raise_error(PermissionError)
        end
      end

      context "user has view privilege on entity" do
        before(:each) do
          add_privilege @login_role, 'view', 'cosmos_entities'
        end

        it "does not raise permission error" do
          g = create(:galaxy)
          lambda {
            @s.get_entities 'with_id', g.id
          }.should_not raise_error(PermissionError)
        end

        it "returns corresponding entity" do
          l  = create(:galaxy)
          rl = @s.get_entities 'with_id', l.id
          rl.should be_an_instance_of(Entities::Galaxy)
          rl.id.should == l.id
        end

        # TODO test name/location matchers
      end
    end

    context "entity id/name/location not specified" do
      it "filters entities user does not have permission to" do
        l1 = create(:galaxy)
        l2 = create(:galaxy)

        # only view privilege on single entity
        add_privilege @login_role, 'view', "cosmos_entity-#{l1.id}"

        ls = @s.get_entities
        ls.size.should == 1
        ls.first.id.should == l1.id
      end
    end

    context "type of entity specified" do
      it "only returns entities matching type" do
        add_privilege @login_role, 'view', 'cosmos_entities'
        g1  = create(:galaxy)
        g2  = create(:galaxy)
        s1  = create(:solar_system)
        r = @s.get_entities 'of_type', 'Cosmos::Entities::Galaxy'
        r.should be_an_instance_of(Array)
        r.size.should == 3
        r[0].id.should == g1.id
        r[1].id.should  == g2.id
        r[2].id.should  == s1.parent_id
      end
    end

    context "recursive set to false" do
      it "only return ids of children and child locations" do
        add_privilege @login_role, 'view', 'cosmos_entities'
        g1  = create(:galaxy)
        s1  = create(:solar_system, :galaxy => g1)
        p1  = create(:planet, :solar_system => s1)
        r = @s.get_entities 'with_id', g1.id, 'recursive', false
        r.id.should == g1.id
        r.children.size.should == 1
        r.children.first.should == s1.id
        r.location.children.size.should == 1
        r.location.children.first.should == s1.location.id
      end
    end
  end # describe #get_entities

  describe "#dispatch_cosmos_rjr_get" do
    it "adds cosmos::get_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_get(d)
      d.handlers.keys.should include("cosmos::get_entity")
    end

    it "adds cosmos::get_entities to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_get(d)
      d.handlers.keys.should include("cosmos::get_entities")
    end
  end

end #module Cosmos::RJR
