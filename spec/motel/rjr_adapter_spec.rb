# rjr adapter tests
#
# Copyright (C) 2012 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require File.dirname(__FILE__) + '/../spec_helper'
require 'rjr/local_node'

describe Motel::RJRAdapter do

  before(:all) do
    Motel::RJRAdapter.init
    @local_node = RJR::LocalNode.new :node_id => 'omega-test'
  end

  after(:all) do
    Motel::Runner.instance.stop
  end

  it "should require view locations to get_all_locations" do
    TestUser.create.clear_privileges
    lambda{
      @local_node.invoke_request('get_all_locations')
    }.should raise_error(Exception)
  end

  it "should return all locations" do
    loc1 = Motel::Location.new :id => 42, :movement_strategy => TestMovementStrategy.new

    TestUser.create.login(@local_node).clear_privileges.add_privilege('view', 'locations')
    Motel::Runner.instance.clear
    locations = @local_node.invoke_request('get_all_locations')
    locations.size.should == 0

    Motel::Runner.instance.run loc1
    locations = @local_node.invoke_request('get_all_locations')
    locations.size.should == 1
    locations.first.id.should == 42
  end

  #get_location
  #create_location
  #update_location
  #track_movement
  #track_proximity
  #remove_callbacks
  #motel::save_state
  #motel::restore_state

end
