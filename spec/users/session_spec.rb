# session module tests
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'timecop'

require 'users/session'

module Users
describe Session do
  after(:all) do
    Timecop.return
  end

  describe "#initialize" do
    it "sets attributes" do
      id = Motel.gen_uuid
      u = User.new :id => 'user1'
      s = Session.new :id => id, :user => u, :endpoint_id => 'node1'
      s.id.should == id
      s.user.id.should == 'user1'
      s.refreshed_time.should_not be_nil
      s.endpoint_id.should == 'node1'
    end
  end

  describe "#timed_out" do
    before(:each) do
      Timecop.freeze
      @u = User.new :id => 'user1'
      @s = Session.new :id => 'id', :user => @u
    end

    after(:each) do
      Timecop.travel
    end

    context "timeout has passed" do
      it "returns true" do
        Timecop.freeze Session::SESSION_EXPIRATION + 1
        @s.timed_out?.should be_true
      end
    end

    context "timeout has not passed" do
      it "returns false" do
        @s.timed_out?.should be_false
        @s.instance_variable_get(:@refreshed_time).should == Time.now
      end
    end

    context "user is permenant" do
      it "always returns false" do
        @u.permenant = true
        Timecop.freeze Session::SESSION_EXPIRATION + 1
        @s.timed_out?.should be_false
      end
    end
  end

  describe "#to_json" do
    it "returns json representation of session" do
      u = User.new :id => 'user1'
      s = Session.new :id => '1234', :user => u, :endpoint_id => 'node1'

      j = s.to_json
      j.should include('"json_class":"Users::Session"')
      j.should include('"id":"1234"')
      j.should include('"json_class":"Users::User"')
      j.should include('"id":"user1"')
      j.should include('"refreshed_time":')
      j.should include('"endpoint_id":"node1"')
    end
  end

  describe "#json_create" do
    it "returns session from json format" do
      j = '{"json_class":"Users::Session","data":{"user":{"json_class":"Users::User","data":{"id":"user1","email":null,"roles":null,"permenant":false,"npc":false,"attributes":null,"password":null,"registration_code":null}},"id":"1234","refreshed_time":"2013-05-30 00:43:54 -0400"}}'
      s = ::RJR::JSONParser.parse(j)

      s.class.should == Users::Session
      s.id.should == "1234"
      s.user.id.should == 'user1'
      s.refreshed_time.should_not be_nil
    end
  end

end # describe Session
end # module Users
