# manufactured::get_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/get'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#get_entity" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Manufactured::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
    end

    it "returns list of all entities" do
      # grant user permissions to view all manufactured_entities
      add_privilege @login_role, 'view', 'manufactured_entities'

      create(:valid_ship)
      create(:valid_station)
      n = Manufactured::RJR.registry.entities.size
      i = Manufactured::RJR.registry.entities.collect { |e| e.id }
      s = @s.get_entities
      s.size.should == n
      s.collect { |e| e.id }.should == i
    end

    context "entity id specified" do
      context "entity not found" do
        it "raises DataNotFound" do
          lambda {
            @s.get_entities 'with_id', 'nonexistant'
          }.should raise_error(DataNotFound)
        end
      end

      context "user does not have view privilege on entity" do
        it "raises PermissionError" do
          l = create(:valid_ship)
          lambda {
            @s.get_entities 'with_id', l.id
          }.should raise_error(PermissionError)
        end
      end

      context "user has view privilege on entity" do
        it "returns corresponding entity" do
          add_privilege @login_role, 'view', 'manufactured_entities'
          l  = create(:valid_ship)
          rl = @s.get_entities 'with_id', l.id
          rl.should be_an_instance_of(entity)
          rl.id.should == l.id
        end
      end
    end

    context "with_location specified" do
      context "entity not found" do
        it "raises DataNotFound"
      end

      context "user does not have view privilege on entity" do
        it "raises PermissionError"
      end

      context "user has view privilege on entity" do
        it "returns corresponding entity"
      end
    end

    context "entity id and location id not specified" do
      it "filters entities user does not have permission to" do
        l1 = create(:valid_ship)
        l2 = create(:valid_ship)

        # only view privilege on single entity
        add_privilege @login_role, 'view', "manufactured_entity-#{l1.id}"

        ls = @s.get_entities
        ls.size.should == 1
        ls.first.id.should == l1.id
      end
    end

    context "type of entity specified" do
      it "returns entities of specified type"
    end

    context "owner of entity specified" do
      it "returns entities owned by specified user"
    end

    context "parent of entity specified" do
      it "returns entities under specified parent"
    end
  end # describe #get_entities

  describe "#dispatch_manufactured_rjr_get" do
    it "adds manufactured::get_entities to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_get(d)
      d.handlers.keys.should include("manufactured::get_entities")
    end

    it "adds manufactured::get_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_get(d)
      d.handlers.keys.should include("manufactured::get_entity")
    end
  end

end #module Manufactured::RJR
