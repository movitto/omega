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
    it "sets user" do
      u = Users::User.new
      ru = RegisteredUser.new u
      ru.user.should == u
    end

    it "sets event id" do
      ru = RegisteredUser.new
      ru.id.should == RegisteredUser::ID
    end
  end

  describe "#to_json" do
    it "returns the event in json format" do
      u = Users::User.new :id => 'user1'
      ru = RegisteredUser.new u

      j = ru.to_json
      j.should include('"json_class":"Users::Events::RegisteredUser"')
      j.should include('"json_class":"Users::User"')
      j.should include('"id":"user1"')
    end
  end

end # describe RegisteredUser
end # module Events
end # module Users
