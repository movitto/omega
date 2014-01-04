# Registered User Event class tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/events/registered_user'

module Users
module Events
describe RegisteredUser do
  describe "#initialize" do
    before(:each) do
      @u = Users::User.new :id => 'user1'
    end

    it "sets user" do
      ru = RegisteredUser.new :user => @u
      ru.user.should == @u
    end

    it "sets event id" do
      ru = RegisteredUser.new :user => @u
      ru.id.should == RegisteredUser::TYPE + '-' + @u.id
    end

    it "sets event type" do
      ru = RegisteredUser.new :user => @u
      ru.type.should == RegisteredUser::TYPE
    end
  end

  describe "#to_json" do
    it "returns the event in json format" do
      u = Users::User.new :id => 'user1'
      ru = RegisteredUser.new :user => u

      j = ru.to_json
      j.should include('"json_class":"Users::Events::RegisteredUser"')
      j.should include('"json_class":"Users::User"')
      j.should include('"id":"user1"')
    end
  end

end # describe RegisteredUser
end # module Events
end # module Users
