# rjr adapter tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'rjr/local_node'

describe Missions::RJRAdapter do

  before(:each) do
  end

  after(:each) do
    Missions::Registry.instance.terminate
    FileUtils.rm_f '/tmp/missions-test' if File.exists?('/tmp/missions-test')
  end

  it "should permit users with create missions_event to create_event" do
  end

  it "should permit users with create missions_mission to create_mission" do
  end

  it "should handle manufactured events and run them as mission events" do
  end

  it "should permit local nodes to save and restore state" do
  end
end
