# motel::get_location tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/get'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#get_location", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    it "returns list of all entities" do
      # grant user permissions to view all locations
      add_privilege @login_role, 'view', 'locations'

      create(:location)
      create(:location)
      n = Motel::RJR.registry.entities.size
      i = Motel::RJR.registry.entities.collect { |e| e.id }
      s = @s.get_location
      s.size.should == n
      s.collect { |e| e.id }.should == i
    end

    context "location id specified" do
      context "entity not found" do
        it "raises DataNotFound" do
          lambda {
            @s.get_location 'with_id', 'nonexistant'
          }.should raise_error(DataNotFound)
        end
      end

      context "user does not have view privilege on entity" do
        it "raises PermissionError" do
          l = create(:location)
          lambda {
            @s.get_location 'with_id', l.id
          }.should raise_error(PermissionError)
        end

        context "restrict view is disabled" do
          it "does not raise permission error" do
            l = create(:location, :restrict_view => false)
            lambda {
              @s.get_location 'with_id', l.id
            }.should_not raise_error
          end

          it "returns corresponding location" do
            l = create(:location, :restrict_view => false)
            rl = @s.get_location 'with_id', l.id
            rl.should be_an_instance_of(Location)
            rl.id.should == l.id
          end
        end
      end

      context "user has view privilege on entity" do
        before(:each) do
          add_privilege @login_role, 'view', 'locations'
        end

        it "returns corresponding location" do
          l  = create(:location)
          rl = @s.get_location 'with_id', l.id
          rl.should be_an_instance_of(Location)
          rl.id.should == l.id
        end
      end
    end

    context "entity id not specified" do
      it "filters entities user does not have permission to" do
        l1 = create(:location)
        l2 = create(:location)

        # only view privilege on single location
        add_privilege @login_role, 'view', "location-#{l1.id}"

        ls = @s.get_location
        ls.size.should == 1
        ls.first.id.should == l1.id
      end
    end

    context "within distance of location specified" do
      before(:each) do
        @l1 = create(:location, :x => 100, :y => 100, :z => 100)
        @l2 = create(:location, :x => -100, :y => -100, :z => -100)

        # privileges on all locations
        add_privilege @login_role, 'view', 'locations'

      end

      it "only returns entities matching critieria" do
        ls = @s.get_location :within, 10, 'of',
                 Location.new(:x => 100, :y => 100, :z => 100)
        ls.size.should == 1
        ls.first.id.should == @l1.id
      end

      context "distance is invalid" do
        it "raises a ValidationError" do
          lambda {
            @s.get_location :within, "10", "of",
                 Location.new(:x => 100, :y => 100, :z => 100)
          }.should raise_error(ValidationError)

          lambda {
            @s.get_location :within, -10, "of",
                 Location.new(:x => 100, :y => 100, :z => 100)
          }.should raise_error(ValidationError)
        end
      end

      context "'of' is invalid" do
        it "raises a ValidationError" do
          lambda {
            @s.get_location :within, 10, "on",
                 Location.new(:x => 100, :y => 100, :z => 100)
          }.should raise_error(ValidationError)
        end
      end

      context "other location is not a Location" do
        it "raises a ValidationError" do
          lambda {
            @s.get_location :within, 10, "of", "Foobar"
          }.should raise_error(ValidationError)
        end
      end
    end
  end # describe #get_entities

  describe "#dispatch_motel_rjr_get" do
    it "adds motel::get_locations to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_get(d)
      d.handlers.keys.should include("motel::get_locations")
    end

    it "adds motel::get_location to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_get(d)
      d.handlers.keys.should include("motel::get_location")
    end
  end

end #module Motel::RJR
