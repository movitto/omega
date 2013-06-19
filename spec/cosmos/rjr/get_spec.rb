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

      # XXX stub out call to motel::create_location
      Cosmos::RJR.node.stub(:invoke).and_return(build(:location))

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
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

    it "updates all entities and children with motel location (recursively)"

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

        it "does not raise permission error"

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
      it "only returns entities matching type"
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
