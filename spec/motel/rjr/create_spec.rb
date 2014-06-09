# motel::create_location tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/create'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#create_location", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :CREATE_METHODS
      @registry = Motel::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "insufficient privileges (create-locations)" do
      it "raises PermissionError" do
        new_location = build(:location)
        lambda {
          @s.create_location(new_location)
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (create-locations)" do
      before(:each) do
        add_privilege(@login_role, 'create', 'locations')
      end

      it "does not raise PermissionError" do
        new_location = build(:location)
        lambda {
          @s.create_location(new_location)
        }.should_not raise_error
      end

      context "non-location specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_location(42)
          }.should raise_error(ValidationError)
        end
      end

      context "invalid location specified" do
        it "raises ValidationError" do
          lambda {
            @s.create_location(Location.new)
          }.should raise_error(ValidationError)
        end
      end

      it "filters properties set on location" do
        new_location = build(:location)
        @s.should_receive(:filter_properties).
           with(new_location, :allow =>
             [:id, :parent_id, :restrict_view, :restrict_modify,
              :x, :y, :z,
              :orientation_x, :orientation_y, :orientation_z,
              :movement_strategy]).and_return(new_location) # XXX should be and_call_original but this is not working for some reason...
        @s.create_location(new_location)
      end

      context "existing location-id specified" do
        it "raises OperationError" do
          loc = create(:location)
          lambda {
            @s.create_location(loc)
          }.should raise_error(OperationError)
        end
      end

      it "creates new location in registry" do
        new_location = build(:location)
        lambda {
          @s.create_location(new_location)
        }.should change{@registry.entities.size}.by(1)
        @registry.entity(&with_id(new_location.id)).should_not be_nil
      end

      it "returns location" do
        new_location = build(:location)
        r = @s.create_location(new_location)
        r.should be_an_instance_of(Location)
        r.id.should == new_location.id
      end
    end

  end # describe "#create_location"

  describe "#dispatch_motel_rjr_create" do
    it "adds motel::create_location to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_create(d)
      d.handlers.keys.should include("motel::create_location")
    end
  end

end #module Motel::RJR
