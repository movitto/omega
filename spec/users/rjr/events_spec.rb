# users::subscribe_to, users::unsubscribe tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/events'
require 'rjr/dispatcher'

module Users::RJR
  describe "#delete_handler_for" do
    it "removes registry handler for specified event/endpoint"
  end

  describe "#subscribe_to", :rjr => true do
    it "creates new persistant event handler for event/endpoint"

    context "handler invoked" do
      context "insufficient permissions (view-users_events)" do
        it "deletes handler from registry"
      end

      it "sends notification of users::event_occurred via rjr callback"

      context "conntection error during notification" do
        it "deletes handler from registry"
      end

      context "other error (generic)" do
        it "deletes handler from registry"
      end
    end

    context "rjr connection closed" do
      it "deletes handler from registry"
    end

    it "removes old handler for event_type/endpoint"

    it "adds event handler to registry"

    it "returns nil"
  end

  describe "#unsubscribe", :rjr => true do
    context "insufficient permissions (view-users_events)" do
      it "raises PermissionError"
    end

    it "deletes handler for event/endpoint from registry"
    it "returns nil"
  end

  describe "#dispatch_users_rjr_events" do
    it "adds users::subscribe_to to dispatcher"
    it "adds users::unsubscribe to dispatcher"
  end
end # module Users::RJR
