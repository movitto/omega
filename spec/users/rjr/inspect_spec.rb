# users::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/inspect'
require 'rjr/dispatcher'

module Users::RJR
  describe "#status", :rjr => true do
    before(:each) do
      dispatch_to @s, Users::RJR, :INSPECT_METHODS
    end

    it "returns users.size" do
      n = Users::RJR.registry.entities { |e| e.is_a?(Users::User) }.size
      Users::RJR.registry << build(:user, :roles => [])
      Users::RJR.registry << build(:user, :roles => [])
      @s.get_status[:users].should == n + 2
    end

    it "returns list of active session ids/user-ids that they belong to" do
      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id

      n = Users::RJR.registry.entities { |e| e.is_a?(Users::Session) }.size
      session_id @s.login(@n, @login_user.id, @login_user.password)

      sessions = @s.get_status[:sessions]
      sessions.size.should == n + 1

      rs = Users::RJR.registry.entities { |e| e.is_a?(Users::Session) }.
                               collect  { |s| s.id }
      ru = Users::RJR.registry.entities { |e| e.is_a?(Users::User) }.
                               collect  { |u| u.id }
      rs.each { |s| sessions.keys.should include(s)   }
      ru.each { |u| sessions.values.should include(u) }
    end

    it "returns roles along with privileges they entail and users that have them" do
      r1 = build(:role)
      r2 = build(:role)
      r2.add_privilege('view', 'entities')
      u1 = build(:user, :roles => [r1])
      u2 = build(:user, :roles => [r1])
      u3 = build(:user, :roles => [r2])
      Users::RJR.registry << r1
      Users::RJR.registry << r2
      Users::RJR.registry << u1
      Users::RJR.registry << u2
      Users::RJR.registry << u3

      roles = @s.get_status[:roles]
      roles.size.should == 3 # roles above + 'user_role_users'
      roles[r1.id][:users].should == [u1.id, u2.id]
      roles[r2.id][:users].should == [u3.id]
      roles[r2.id][:privileges].should == ['privilege-view-entities']
    end

  end # describe "#status"

  describe "#dispatch_users_rjr_inspect" do
    it "adds users::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_inspect(d)
      d.handlers.keys.should include("users::status")
    end
  end

end #module Users::RJR
