# motel::track*,motel::remove_callbacks tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/track'
require 'motel/callbacks/movement'
require 'motel/callbacks/stopped'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#track_handler" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :TRACK_METHODS
      @registry = Motel::RJR.registry

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
    end

    context "specified loc_id not found" do
      it "raises DataNotFound" do
        lambda {
          @s.track_handler 'nonexistant'
        }.should raise_error(DataNotFound)
      end
    end

    it "returns nil" do
      l = create(:location)
      @s.track_handler(l.id, 20).should be_nil
    end

    it "adds a new location callback to registry location" do
      l = create(:location)
      @s.track_handler l.id, 20
      @registry.entity(&with_id(l.id)).
                callbacks[:movement].size.should == 1
    end

    it "sets endpoint id on location callback" do
      l = create(:location)
      @s.instance_variable_get(:@rjr_headers)['source_node'] = 'foobar'
      @s.track_handler l.id, 20
      @registry.entity(&with_id(l.id)).
                callbacks[:movement].first.endpoint_id.should == 'foobar'
    end

    it "sets handler on location callback" do
      l = create(:location)
      @n.message_headers['source_node'] = 'foobar'
      @s.track_handler l.id, 20
      @registry.entity(&with_id(l.id)).
                callbacks[:movement].first.
                should be_an_instance_of(Callbacks::Movement)
    end

    context "callback handler invoked" do
      before(:each) do
        @l = create(:location)
        @s.track_handler @l.id, 20
        @cb = @registry.safe_exec{
          @registry.instance_variable_get(:@entities).
                    find(&with_id(@l.id)).callbacks[:movement].first
        }
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
                    callbacks[:movement].size.should == 0
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
                      callbacks[:proximity].size.should == 0
          end

          it "does not invoke callback rjr_event" do
            @n.should_not_receive(:notify)#.with("motel::on_proximity")
            @cb.invoke @l
          end
        end
      end

      context "other exception during callback handler" do
        it "removes callback from location"
      end
    end

    context "rjr connection closed" do
      it "removes callback from location"
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
        @s.track_handler l.id, 1.57
        @registry.entity(&with_id(l.id)).
                  callbacks[:rotation].size.should == 1
      end

      it "accepts rotation as second parmaeter" do
        l = create(:location)
        @s.track_handler l.id, 1.57
        @registry.entity(&with_id(l.id)).
                  callbacks[:rotation].first.min_rotation.should == 1.57
      end

      context "rotation is invalid" do
        it "raises ArgumentError" do
          l = create(:location)
          lambda {
            @s.track_handler l.id, "1.57"
          }.should raise_error(ArgumentError)
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


  end # describe #track_handler

  describe "#remove_callbacks" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      dispatch_to @s, Motel::RJR, :TRACK_METHODS

      @login_user = create(:user)
      @login_role = 'user_role_' + @login_user.id
      session_id @s.login(@n, @login_user.id, @login_user.password)

      @registry = Motel::RJR.registry
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
        l = create(:location)
        lambda {
          @s.remove_callbacks l.id, 'invalid'
        }.should raise_error(ArgumentError)
      end
    end

    context "insufficient permissions" do
      it "should raise PermissionError"
    end

    it "removes location callbacks" do
      l = create(:location)
      @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
      @s.track_handler l.id, 20
      @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
      @s.track_handler l.id, 1.57
      lambda {
        @s.remove_callbacks l.id
      }.should change{@registry.entity(&with_id(l.id)).
                                callbacks.values.size}.by(-2)
    end

    it "only removed callbacks for the rjr_node"

    context "callback type is specified" do
      it "remove location callbacks of specified type" do
        l = create(:location)
        @s.instance_variable_set(:@rjr_method, 'motel::track_movement')
        @s.track_handler l.id, 20
        @s.instance_variable_set(:@rjr_method, 'motel::track_rotation')
        @s.track_handler l.id, 1.57
        lambda {
          @s.remove_callbacks l.id, 'rotation'
        }.should change{@registry.entity(&with_id(l.id)).
                                  callbacks.values.flatten.size}.by(-1)
        @registry.entity(&with_id(l.id)).callbacks[:movement].size.should == 1
        @registry.entity(&with_id(l.id)).callbacks[:proximity].should be_nil
      end
    end

  end # describe #remove_callbacks

  describe "#dispatch_motel_rjr_track" do
    ['movement', 'rotation', 'proximity', 'stops'].each { |t|
      it "adds motel::track_#{t} to dispatcher" do
        d = ::RJR::Dispatcher.new
        dispatch_motel_rjr_track(d)
        d.handlers.keys.should include("motel::track_#{t}")
      end
    }

    it "adds motel::remove_callbacks to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_track(d)
      d.handlers.keys.should include("motel::remove_callbacks")
    end
  end

end #module Motel::RJR
