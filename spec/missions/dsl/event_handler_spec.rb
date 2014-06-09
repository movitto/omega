# Missions DSL EventHandler Module tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/dsl/event_handler'

module Missions
module DSL
  describe EventHandler do
    before(:each) do
      @node = Missions::RJR::node.as_null_object
    end

    describe "#on_event_create_entity" do
      it "returns nil by default" do
        EventHandler.on_event_create_entity.should be_nil
      end

      context "registered_user event" do
        before(:each) do
          @user  = build(:user)
          @event = Missions::Events::Users.new :users_event_args =>
                     ['registered_user', @user]
        end

        it "generates a proc" do
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       should be_an_instance_of(Proc)
        end

        it "creates a new id if not specified" do
          @node.should_receive(:invoke).with { |*args|
            args[1].id.should =~ UUID_PATTERN
          }
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       call @event
        end

        it "retrieves user id from registered_user event args" do
          @node.should_receive(:invoke).with { |*args|
            args[1].user_id.should == @user.id
          }
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       call @event
        end

        it "creates new entity of the specified type" do
          @node.should_receive(:invoke).with { |*args|
            args[1].should be_an_instance_of(Manufactured::Ship)
          }
          EventHandler.on_event_create_entity(:event => 'registered_user',
                                              :entity_type => 'Manufactured::Ship').
                       call @event
        end

        it "invokes manufactured::create_entity to create entity" do
          @node.should_receive(:invoke).with { |*args|
            args[0].should == 'manufactured::create_entity'
          }
          EventHandler.on_event_create_entity(:event => 'registered_user').
                       call @event
        end
      end
    end

    describe "#on_event_add_role" do
      it "returns nil by default" do
        EventHandler.on_event_add_role.should be_nil
      end

      context "registered_user event" do
        before(:each) do
          @user  = build(:user)
          @event = Missions::Events::Users.new :users_event_args =>
                     ['registered_user', @user]
        end

        it "generates a proc" do
          EventHandler.on_event_add_role(:event => 'registered_user').
                       should be_an_instance_of(Proc)
        end

        it "retrieves user id from registered_user event args" do
          @node.should_receive(:invoke).with { |*args|
            args[1].should == @user.id
          }
          EventHandler.on_event_add_role(:event => 'registered_user').
                       call @event
        end

        it "invokes users::add_role" do
          @node.should_receive(:invoke).with { |*args|
            args[0].should == 'users::add_role'
            args[2].should == 'regular_user'
          }
          EventHandler.on_event_add_role(:event => 'registered_user',
                                         :role  => 'regular_user').
                       call @event
        end
      end
    end
  end # describe EventHandler
end # module DSL
end # module Missions
