# cosmos::create_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/create'
require 'motel/rjr/create'
require 'rjr/dispatcher'

module Cosmos::RJR
  describe "#create_entity", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :CREATE_METHODS
      @registry = Cosmos::RJR.registry

      # XXX needed to handle motel::create_location calls
      @n.dispatcher.add_module('motel/rjr/init')
      @n.dispatcher.add_module('cosmos/rjr/init')

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      #add_privilege @login_role, 'create', 'locations'
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "insufficient privileges (create-cosmos_entities)" do
      it "raises PermissionError" do
        new_entity = build(:galaxy)
        lambda {
          @s.create_entity(new_entity)
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (create-cosmos_entities)" do
      before(:each) do
        add_privilege(@login_role, 'create', 'cosmos_entities')
      end

      it "does not raise PermissionError" do
        new_entity = build(:galaxy)
        lambda {
          @s.create_entity(new_entity)
        }.should_not raise_error(PermissionError)
      end

      context "non-entity specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_entity(42)
          }.should raise_error(ValidationError)
        end
      end

      context "invalid entity specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_entity(Entities::Galaxy.new)
          }.should raise_error(ValidationError)
        end
      end

      it "creates location" do
        new_entity = build(:galaxy)
        Cosmos::RJR.node.should_receive(:invoke).
          with('motel::create_location', new_entity.location).and_call_original
        @s.create_entity(new_entity)
      end

      it "sets location id" do
        new_entity = build(:galaxy)
        @s.create_entity(new_entity)
        Motel::RJR.registry.entities.last.id.should == new_entity.id
      end

      it "sets location parent" do
        new_entity = build(:galaxy)
        @s.create_entity(new_entity)
        Motel::RJR.registry.entities.last.parent_id.should == new_entity.parent_id
      end

      context "existing entity-id specified" do
        # TODO other errors such as parent not found
        it "raises OperationError" do
          entity = create(:galaxy)
          lambda {
            @s.create_entity(entity)
          }.should raise_error(OperationError)
        end
      end

      context "existing entity-name specified" do
        it "raises OperationError" do
          entity = create(:galaxy)
          entity2 = create(:galaxy, :name => entity.name)
          lambda {
            @s.create_entity(entity2)
          }.should raise_error(OperationError)
        end
      end

      it "creates new entity in registry" do
        new_entity = build(:galaxy)
        lambda {
          @s.create_entity(new_entity)
        }.should change{@registry.entities.size}.by(1)
        @registry.entity(&with_id(new_entity.id)).should_not be_nil
      end

      it "returns entity" do
        new_entity = build(:galaxy)
        r = @s.create_entity(new_entity)
        r.should be_an_instance_of(Entities::Galaxy)
        r.id.should == new_entity.id
      end
    end

  end # describe "#create_entity"

  describe "#dispatch_cosmos_rjr_create" do
    it "adds users::create_entity to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_cosmos_rjr_create(d)
      d.handlers.keys.should include("cosmos::create_entity")
    end
  end

end #module Cosmos::RJR
