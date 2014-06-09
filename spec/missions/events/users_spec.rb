# Users Event class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/events/users'
require 'users/user'

module Missions
module Events
describe Users do
  describe "#initialize" do
    before(:each) do
      @u = build(:user)
      @args = ['registered_user', @u]
    end

    it "sets users event args" do
      u = Missions::Events::Users.new :users_event_args => @args
      u.users_event_args.should == @args
    end

    it "sets event from user event type" do
      u = Missions::Events::Users.new :users_event_args => @args
      u.id.should == @args.first
    end
  end

  describe "#to_json" do
    it "returns the event in json format" do
      u = ::Users::User.new :id => 'user1'
      u = Missions::Events::Users.new 'users_event_args' => ['registered_user', u]
      j = u.to_json
      j.should include('"json_class":"Missions::Events::Users"')
      j.should include('"users_event_args":["registered_user",')
      j.should include('"json_class":"Users::User"')
      j.should include('"id":"user1"')
    end
  end

end # describe Manufactured
end # module Events
end # module Missions
