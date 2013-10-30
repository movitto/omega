# motel::update_location test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/update'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#update_location", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :UPDATE_METHODS
      @registry = Motel::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "parameter not an instance of location" do
      it "raises ValidationError" do
        lambda {
          @s.update_location 42
        }.should raise_error(ValidationError)
      end
    end

    context "location is invalid" do
      it "raises ValidationError" do
        lambda{
          @s.update_location build(:location, :x => :foobar)
        }.should raise_error(ValidationError)
      end
    end

    context "location is nil" do
      it "raises ValidationError" do
        lambda{
          @s.update_location build(:location, :id => nil)
        }.should raise_error(ValidationError)
      end
    end

    context "location cannot be found" do
      it "raises DataNotFound" do
        n = build(:location)
        lambda {
          @s.update_location n
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient privileges (modify-locations)" do
      it "raises PermissionError" do
        n = create(:location)
        lambda {
          @s.update_location n
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges (modify-locations)" do
      before(:each) do
        add_privilege @login_role, 'modify', 'locations'
      end

      it "filters invalid properties" do
        n = create(:location)
        @s.should_receive(:filter_properties).
           with(n, :allow => [:id,:x,:y,:z,:parent_id,
                              :movement_strategy,
                              :next_movement_strategy])
        @s.update_location n
      end

      it "updates location in registry" do
        n = create(:location)
        n.x = 5000
        @s.update_location n
        Motel::RJR.registry.entity(&with_id(n.id)).x.should == 5000
      end
      
      it "returns location" do
        n = create(:location)
        @s.update_location(n).id.should == n.id
      end
    end
  end # describe "#update_location"

  describe "#dispatch_motel_rjr_update" do
    it "adds motel::update_location to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_update(d)
      d.handlers.keys.should include("motel::update_location")
    end
  end

end #module Users::RJR
