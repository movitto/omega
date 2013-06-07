# stats/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'stats/rjr/init'

module Stats::RJR
  describe "#user_registry" do
    it "provides access to Users::RJR.registry" do
      rjr = Object.new.extend(Stats::RJR)
      rjr.user_registry.should == Stats::RJR.user_registry
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Stats::RJR)
      Stats::RJR.user_registry.should equal(rjr.user_registry)
    end
  end

  describe "#user" do
    it "provides centralized user" do
      rjr = Object.new.extend(Stats::RJR)
      rjr.user.should be_an_instance_of Users::User
      rjr.user.valid_login?(Stats::RJR.stats_rjr_username,
                            Stats::RJR.stats_rjr_password)

      rjr.user.should equal(rjr.user)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Stats::RJR)
      Stats::RJR.user.should equal(rjr.user)
    end
  end

  describe "#dispatch_stats_rjr_init" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Stats::RJR)
    end

    it "dispatches stats* in Stats::RJR environment" do
      dispatch_stats_rjr_init(@d)
      @d.environments[/stats::.*/].should == Stats::RJR
    end

    it "adds stats rjr modules to dispatcher"

    it "sets dispatcher on node" do
      dispatch_stats_rjr_init(@d)
      @rjr.node.dispatcher.should == @d
    end

    it "sets source_node message header on node" do
      dispatch_stats_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should == 'stats'
    end

    it "creates the user" do
      dispatch_stats_rjr_init(@d)
      Users::RJR.registry.entity(&with_id(Stats::RJR.user.id)).should_not be_nil
    end

    context "user exists" do
      it "does not raise error" do
        Users::RJR.registry.entities << Stats::RJR.user
        lambda{
          dispatch_stats_rjr_init(@d)
        }.should_not raise_error
      end
    end

    it "logs in the user using the node" do
      lambda{ # XXX @d.add_module above will have already called dispatch_init
        dispatch_stats_rjr_init(@d)
      }.should change{Users::RJR.registry.entities.size}.by(3)
      Users::RJR.registry.
                 entity(&matching{ |s| s.is_a?(Users::Session) &&
                                       s.user.id == Stats::RJR.user.id }).
                 should_not be_nil
    end

    it "sets session if on node" do
      dispatch_stats_rjr_init(@d)
      @rjr.node.message_headers['source_node'].should_not be_nil
    end
  end

end # module Stats::RJR
