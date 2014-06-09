# motel::track*,motel::remove_callbacks tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/track'
require 'motel/callbacks/movement'
require 'motel/callbacks/stopped'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#track_handler", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :TRACK_METHODS
      @registry = Motel::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      @session = @s.login(@n, @login_user.id, @login_user.password)
      session_id  @session
      source_node @session

      @s.instance_variable_set(:@rjr_method, 'motel::track_movement')

      @l = create(:location)
    end

    context "specified loc_id not found" do
      it "raises DataNotFound" do
        lambda {
          @s.track_handler 'nonexistant'
        }.should raise_error(DataNotFound)
      end
    end

    context "rjr transport is not persistent" do
      it "raises an OperationError" do
        @n.should_receive(:persistent?).and_return(false)
        lambda {
          @s.track_handler @l.id, 20
        }.should raise_error(OperationError)
      end
    end

    context "invalid source node" do
      it "raises a PermissionError" do
        source_node 42
        lambda {
          @s.track_handler @l.id, 20
        }.should raise_error(PermissionError)
      end
    end

    context "source node / session source mismatch" do
      it "raises a PermissionError" do
        source_node 'mismatch'
        lambda {
          @s.track_handler @l.id, 20
        }.should raise_error(PermissionError)
      end
    end

    it "returns nil" do
      @s.track_handler(@l.id, 20).should be_nil
    end

    it "adds a new location callback to registry location" do
      @s.track_handler @l.id, 20
      @registry.entity(&with_id(@l.id)).
                callbacks[:movement].size.should == 1
    end

    it "sets endpoint id on location callback" do
      # update source_node and session endpoint to avoid mismatch error
      source_node 'foobar'
      Users::RJR.registry.proxy_for(&with_id(@session.id)).endpoint_id = 'foobar'

      @s.track_handler @l.id, 20
      @registry.entity(&with_id(@l.id)).
                callbacks[:movement].first.endpoint_id.should == 'foobar'
    end

    context "source node is invalid" do
      it "raises a PermissionError" do
        @s.instance_variable_get(:@rjr_headers)['source_node'] = nil
        lambda{
          @s.track_handler @l.id, 20
        }.should raise_error(PermissionError)

        @s.instance_variable_get(:@rjr_headers)['source_node'] = ''
        lambda{
          @s.track_handler @l.id, 20
        }.should raise_error(PermissionError)
      end
    end

    it "sets handler on location callback" do
      @n.message_headers['source_node'] = 'foobar'
      @s.track_handler @l.id, 20
      @registry.entity(&with_id(@l.id)).
                callbacks[:movement].first.
                should be_an_instance_of(Callbacks::Movement)
    end

    context "callback handler invoked" do
      before(:each) do
        @rl = @registry.safe_exec { |es| es.find { |e| e.id == @l.id }}

        @s.track_handler @l.id, 20
        @cb = @rl.callbacks[:movement].first

        @cb.instance_variable_set(:@orig_x, 30)
        @cb.instance_variable_set(:@orig_y,  0)
        @cb.instance_variable_set(:@orig_z,  0)

        @s.instance_variable_set(:@rjr_callback, @n)
      end

      it "uses rjr callback to invoke callback rjr_event" do
        # add view permission
        add_privilege @login_role, 'view', 'locations'

        @n.should_receive(:notify)#.with("motel::on_movement")
        @cb.invoke @l, 10, 0, 0
      end

      context "user does not have privilege to view location" do
        it "removes callback from location" do
          @cb.invoke @l, 10, 0, 0
          @registry.entity(&with_id(@l.id)).
                    callbacks[:movement].should be_nil
        end

        it "does not invoke callback rjr_event" do
          @n.should_not_receive(:notify)#.with("motel::on_movement")
          @cb.invoke @l, 10, 0, 0
        end
      end

      context "proximity callback" do
        before(:each) do
          @l2 = create(:location)
          @s.instance_variable_set(:@rjr_method, 'motel::track_proximity')
          @s.track_handler @l.id, @l2.id, 'proximity', 10
          @cb = @registry.safe_exec{
            @registry.instance_variable_get(:@entities).find(&with_id(@l.id)).callbacks[:proximity].first
          }
        end

        context "user does not have privilege to view other location" do
          before(:each) do
            # add priv to view first location only
            add_privilege @login_role, 'view', 'location-' + @l.id.to_s
          end

          it "removes callback from location" do
            @cb.invoke @l
            @registry.entity(&with_id(@l.id)).
                      callbacks[:proximity].should be_nil
          end

          it "does not invoke callback rjr_event" do
            @n.should_not_receive(:notify)#.with("motel::on_proximity")
            @cb.invoke @l
          end
        end
      end

      context "other exception during callback handler" do
        it "removes callback from location" do
          add_privilege @login_role, 'view', 'locations'
          @n.should_receive(:notify).and_raise(Exception)
          lambda{
            @cb.invoke @l, 0, 0, 0
          }.should change{@rl.callbacks[:movement].size}.by(-1)
        end
      end
    end

    context "rjr connection closed" do
      it "removes callback from location" do
        @rl = @registry.safe_exec { |es| es.find { |e| e.id == @l.id }}
        @s.track_handler @l.id, 20

        lambda{
          @n.send :connection_event, :closed
        }.should change{@rl.callbacks[:movement].size}.by(-1)
      end
    end

    context "#track_movement" do
      before(:each) do
        @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
      end

      it "creates a movement callback" do
        l = create(:location)
        @s.track_handler l.id, 20
        @registry.entity(&with_id(l.id)).
                  callbacks[:movement].size.should == 1
      end

      it "accepts distance as second parameter" do
        l = create(:location)
        @s.track_handler l.id, 20
        @registry.entity(&with_id(l.id)).
                  callbacks[:movement].first.min_distance.should == 20
      end

      context "distance is invalid" do
        it "raises ArgumentError" do
          l = create(:location)
          lambda {
            @s.track_handler l.id, "20"
          }.should raise_error(ArgumentError)
        end
      end
    end

    context "#track_rotation" do
      before(:each) do
        @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
      end

      it "creates a rotation callback" do
        l = create(:location)
        @s.track_handler l.id, 1.57, 1, 0, 0
        @registry.entity(&with_id(l.id)).
                  callbacks[:rotation].size.should == 1
      end

      it "accepts rotation as second parameter" do
        l = create(:location)
        @s.track_handler l.id, 1.57, 1, 0, 0
        @registry.entity(&with_id(l.id)).
                  callbacks[:rotation].first.rot_theta.should == 1.57
      end

      it "accepts rotation axis as third, fourth, fifth parameters" do
        l = create(:location)
        @s.track_handler l.id, 1.57, -1, 0, 0
        rot = @registry.entity(&with_id(l.id)).
                        callbacks[:rotation].first
        rot.axis_x.should == -1
        rot.axis_y.should ==  0
        rot.axis_z.should ==  0
      end

      context "rotation is invalid" do
        it "raises ArgumentError" do
          l = create(:location)
          lambda {
            @s.track_handler l.id, "1.57", 1, 0, 0
          }.should raise_error(ArgumentError)
        end
      end

      context "rotation axis is invalid" do
        it "raises ArgumentError" do
          l = create(:location)
          lambda {
            @s.track_handler l.id, 1.57, 0.75, 0, 0
          }.should raise_error(ArgumentError)
        end

        context "rotation axis is null" do
          it "does not raise ArgumentError"
        end
      end
    end

    context "#track_proximity" do
      before(:each) do
        @s.instance_variable_set(:@rjr_method, 'motel::track_proximity')
      end

      it "creates a proximity callback" do
        l1 = create(:location)
        l2 = create(:location)
        @s.track_handler l1.id, l2.id, 'proximity', 10
        @registry.entity(&with_id(l1.id)).
                  callbacks[:proximity].size.should == 1
      end

      it "accepts other location id as second parameter" do
        l1 = create(:location)
        l2 = create(:location)
        @s.track_handler l1.id, l2.id, 'proximity', 10
        cb = @registry.entity(&with_id(l1.id)).callbacks[:proximity].first
        cb.to_location.id.should == l2.id
      end

      it "accepts proximity event as third parameter" do
        l1 = create(:location)
        l2 = create(:location)
        @s.track_handler l1.id, l2.id, 'proximity', 10
        cb = @registry.entity(&with_id(l1.id)).callbacks[:proximity].first
        cb.event.should == :proximity
      end

      it "accepts distance as third parameter" do
        l1 = create(:location)
        l2 = create(:location)
        @s.track_handler l1.id, l2.id, 'proximity', 10
        cb = @registry.entity(&with_id(l1.id)).callbacks[:proximity].first
        cb.max_distance.should == 10
      end

      context "other location not found" do
        it "raises DataNotFound" do
          l1 = create(:location)
          lambda {
            @s.track_handler l1.id, 'whatever', 'proximity', 10
          }.should raise_error(DataNotFound)
        end
      end

      context "invalid proximity event" do
        it "raises ArgumentError" do
          l1 = create(:location)
          l2 = create(:location)
          lambda {
            @s.track_handler l1.id, l2.id, 'invalid', 10
          }.should raise_error(ArgumentError)
        end
      end

      context "invalid distance" do
        it "raises ArgumentError" do
          l1 = create(:location)
          l2 = create(:location)
          lambda {
            @s.track_handler l1.id, l2.id, 'proximity', "10"
          }.should raise_error(ArgumentError)
        end
      end
    end

    context "#track_stops" do
      before(:each) do
        @s.instance_variable_set(:@rjr_method, 'motel::track_stops')
      end

      it "creates a stopped callback" do
        l = create(:location)
        @s.track_handler l.id
        @registry.entity(&with_id(l.id)).
                  callbacks[:stopped].size.should == 1
      end
    end

    context "track_strategy" do
      before(:each) do
        @s.instance_variable_set(:@rjr_method, 'motel::track_strategy')
      end

      it "creates a changed_strategy callback" do
        l = create(:location)
        @s.track_handler l.id
        @registry.entity(&with_id(l.id)).
                  callbacks[:changed_strategy].size.should == 1
      end
    end
  end # describe #track_handler

  describe "#dispatch_motel_rjr_track" do
    ['movement', 'rotation', 'proximity', 'stops', 'strategy'].each { |t|
      it "adds motel::track_#{t} to dispatcher" do
        d = ::RJR::Dispatcher.new
        dispatch_motel_rjr_track(d)
        d.handles?("motel::track_#{t}").should be_true
      end
    }
  end

end #module Motel::RJR
