# cosmos::create_entity tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'cosmos/rjr/create'
require 'rjr/dispatcher'

module Cosmos::RJR
  describe "#create_entity" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Cosmos::RJR, :CREATE_METHODS
      @registry = Cosmos::RJR.registry

      # XXX stub out call to motel::create_location
      Cosmos::RJR.node.stub(:invoke).and_return(build(:location))

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @s.login @n, @login_user.id, @login_user.password
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
        Cosmos::RJR.node.should_receive(:invoke).with('motel::create_location', new_entity.location)
        @s.create_entity(new_entity)
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
        it "raises OperationError"
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
