# motel::delete_location tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/delete'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#delete_location", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :DELETE_METHODS
      @registry = Motel::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "insufficient privileges (delete-locations)" do
      it "raises PermissionError" do
        loc = create(:location)
        lambda {
          @s.delete_location(loc.id)
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (delete-locations)" do
      before(:each) do
        add_privilege(@login_role, 'delete', 'locations')
      end

      it "does not raise PermissionError" do
        loc = create(:location)
        lambda {
          @s.delete_location(loc.id)
        }.should_not raise_error
      end

      context "invalid location_id specified" do
        it "raises ValidationError" do
          loc = create(:location)
          lambda {
            @s.delete_location('foobar')
          }.should raise_error(DataNotFound)
        end
      end

      it "deletes location from registry" do
        loc = create(:location)
        lambda {
          @s.delete_location(loc.id)
        }.should change{@registry.entities.size}.by(-1)
        @registry.entity(&with_id(loc.id)).should be_nil
      end

      it "returns nil" do
        loc = create(:location)
        r = @s.delete_location(loc.id)
        r.should be_nil
      end
    end

  end # describe "#delete_location"

  describe "#dispatch_motel_rjr_delete" do
    it "adds motel::delete_location to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_delete(d)
      d.handlers.keys.should include("motel::delete_location")
    end
  end

end #module Motel::RJR
