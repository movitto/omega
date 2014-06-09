# stats::get_stats tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/rjr/get'

module Stats::RJR
  describe "#get_stats", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Stats::RJR, :GET_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)
    end

    context "insufficient privileges (view-stats)" do
      it "raises PermissionError" do
          lambda {
            @s.get_stats 'num_of', 'users'
          }.should raise_error(PermissionError)
      end
    end

    context "sufficient privileges" do
      before(:each) do
        # only view privilege on users
        add_privilege @login_role, 'view', 'stats'
      end

      context "stat id not found" do
        it "raises DataNotFound" do
            lambda {
              @s.get_stats 'invalid'
            }.should raise_error(DataNotFound)
        end
      end

      it "returns stat with the specified id" do
        stat = Stats::Stat.new :id => :foobar, :generator => proc {}
        Stats.should_receive(:get_stat).and_return stat
        r = @s.get_stats :num_of, 'users'
        r.should be_an_instance_of Stats::StatResult
        r.stat_id.should == stat.id
        r.stat.id.should == stat.id
      end

      it "passes other arguments to stat generator" do
        stat = Stats::Stat.new
        stat.should_receive(:generate).with('foobar')
        Stats.should_receive(:get_stat).and_return stat
        @s.get_stats :num_of, 'foobar'
      end
    end
  end

end #module Motel::RJR
