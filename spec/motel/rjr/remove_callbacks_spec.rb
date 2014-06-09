# motel::remove_callbacks tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/remove_callbacks'
require 'motel/rjr/track'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#remove_callbacks", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :REMOVE_CALLBACKS_METHODS

      # also add track so we can register callbacks via track_handler below
      dispatch_to @s, Motel::RJR, :TRACK_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @session = @s.login(@n, @login_user.id, @login_user.password)
      session_id @session

      @registry = Motel::RJR.registry

      @l = create(:location)
    end

    context "insufficient permissions" do
      it "should raise PermissionError" do
        lambda {
          @s.remove_callbacks @l.id
        }.should raise_error(PermissionError)
      end
    end

    context "sufficient permissions" do
      before(:each) do
        add_privilege @login_role, 'view', 'locations'
      end

      context "location not found" do
        it "raises DataNotFound" do
          lambda {
            @s.remove_callbacks 'nonexistant'
          }.should raise_error(DataNotFound)
        end
      end

      context "callback type is invalid" do
        it "raises ArgumentError" do
          lambda {
            @s.remove_callbacks @l.id, 'invalid'
          }.should raise_error(ArgumentError)
        end
      end

      context "invalid source node" do
        it "raises a PermissionError" do
          source_node 42
          lambda {
            @s.remove_callbacks @l.id
          }.should raise_error(PermissionError)
        end
      end

      context "source node / session source mismatch" do
        it "raises a PermissionError" do
          source_node 'mismatch'
          lambda {
            @s.remove_callbacks @l.id
          }.should raise_error(PermissionError)
        end
      end

      it "removes location callbacks" do
        @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
        @s.track_handler @l.id, 20
        @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
        @s.track_handler @l.id, 1.57, 1, 0, 0
        lambda {
          @s.remove_callbacks @l.id
        }.should change{@registry.entity(&with_id(@l.id)).
                                  callbacks.values.size}.by(-2)
      end

      context "callback type is specified" do
        it "remove location callbacks of specified type" do
          @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
          @s.track_handler @l.id, 20
          @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
          @s.track_handler @l.id, 1.57, 1, 0, 0
          lambda {
            @s.remove_callbacks @l.id, 'rotation'
          }.should change{@registry.entity(&with_id(@l.id)).
                                    callbacks.values.flatten.size}.by(-1)
          @registry.entity(&with_id(@l.id)).callbacks[:movement].size.should == 1
          @registry.entity(&with_id(@l.id)).callbacks[:proximity].should be_nil
        end
      end

      it "only removed callbacks for the rjr_node" do
        source_node 'foobar'
        Users::RJR.registry.proxy_for(&with_id(@session.id)).endpoint_id = 'foobar'
        @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
        @s.track_handler @l.id, 20
        @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
        @s.track_handler @l.id, 1.57, 1, 0, 0

        source_node 'barfoo'
        Users::RJR.registry.proxy_for(&with_id(@session.id)).endpoint_id = 'barfoo'
        @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
        @s.track_handler @l.id, 20
        @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
        @s.track_handler @l.id, 1.57, 1, 0, 0

        lambda {
          @s.remove_callbacks @l.id, 'rotation'
        }.should change{@registry.entity(&with_id(@l.id)).
                                  callbacks.values.flatten.size}.by(-1)
        lambda {
          @s.remove_callbacks @l.id
        }.should change{@registry.entity(&with_id(@l.id)).
                                  callbacks.values.flatten.size}.by(-1)

        @registry.entity(&with_id(@l.id)).callbacks[:movement].
                          first.endpoint_id.should == 'foobar'
        @registry.entity(&with_id(@l.id)).callbacks[:rotation].
                          first.endpoint_id.should == 'foobar'
      end
    end
  end # describe #remove_callbacks

  describe "#dispatch_motel_rjr_remove_callbacks" do
    it "adds motel::remove_callbacks to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_remove_callbacks(d)
      d.handles?("motel::remove_callbacks").should be_true
    end
  end

end # module Motel::RJR
