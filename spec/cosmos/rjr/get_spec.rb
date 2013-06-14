# cosmos::get_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/get'
require 'rjr/dispatcher'

module Cosmos::RJR
  describe "#get_entity" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
    end

    it "returns list of all entities" do
      # grant user permissions to view all entitys
      add_privilege @login_role, 'view', 'entitys'

      create(:entity)
      create(:entity)
      n = Cosmos::RJR.registry.entities.size
      i = Cosmos::RJR.registry.entities.collect { |e| e.id }
      s = @s.get_entity
      s.size.should == n
      s.collect { |e| e.id }.should == i
    end

    it "updates all entities and children with motel location (recursively)"

    context "entity id/name specified" do
      context "entity not found" do
        it "raises DataNotFound" do
          lambda {
            @s.get_entity 'with_id', 'nonexistant'
          }.should raise_error(DataNotFound)
        end
      end

      context "user does not have view privilege on entity" do
        it "raises PermissionError" do
          l = create(:entity)
          lambda {
            @s.get_entity 'with_id', l.id
          }.should raise_error(PermissionError)
        end
      end

      context "user has view privilege on entity" do
        before(:each) do
          add_privilege @login_role, 'view', 'entitys'
        end

        it "does not raise permission error"

        it "returns corresponding entity" do
          l  = create(:entity)
          rl = @s.get_entity 'with_id', l.id
          rl.should be_an_instance_of(entity)
          rl.id.should == l.id
        end
      end
    end

    context "entity id not specified" do
      it "filters entities user does not have permission to" do
        l1 = create(:entity)
        l2 = create(:entity)

        # only view privilege on single entity
        add_privilege @login_role, 'view', "entity-#{l1.id}"

        ls = @s.get_entity
        ls.size.should == 1
        ls.first.id.should == l1.id
      end
    end

    context "type of entity specified" do
      it "only returns entities matching type"
    end

    context "location of entity specified" do
      it "only returns entities matching location id"
    end
  end # describe #get_entities

  describe "#dispatch_cosmos_rjr_get" do
    it "adds cosmos::get_entitys to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_get(d)
      d.handlers.keys.should include("cosmos::get_entitys")
    end

    it "adds cosmos::get_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_get(d)
      d.handlers.keys.should include("cosmos::get_entity")
    end
  end

end #module Cosmos::RJR
