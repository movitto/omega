# client user module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/user'

module Omega::Client
  describe User, :rjr => true do
    before(:each) do
      Omega::Client::User.node.rjr_node = @n
    end

    describe "#login" do
      it "logs the specified user in" do
        create(:user, :id => 'foo', :password => 'bar')
        User.login 'foo', 'bar'
        s = Users::RJR.registry.entities.last
        s.should be_an_instance_of(Users::Session)
        s.user.id.should == 'foo'
      end

      it "sets session_id message header on node" do
        create(:user, :id => 'foo', :password => 'bar')
        User.login 'foo', 'bar'
        s = Users::RJR.registry.entities.last
        User.node.rjr_node.message_headers['session_id'].should == s.id
      end
    end

  end # describe User
end # module Omega::Client
