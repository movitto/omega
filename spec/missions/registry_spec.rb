# registry module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

require 'stringio'

describe Manufactured::Registry do

  before(:each) do
    Missions::Registry.instance.init
  end

  after(:each) do
    Missions::Registry.instance.terminate
  end

  it "provide acceses to managed missions" do
  end

  it "provide acceses to managed events" do
  end

  it "should permit global event callback to be registered for event" do
  end

  it "should permit specified global event callback to be removed for event" do
  end

  it "should permit all global event callbacks to be removed for event" do
  end

  it "should run the event cycle" do
  end

  it "should save events ran to the event history list" do
  end

  it "should save registered missions mission and events to io object" do
  end

  it "should restore registered missions entities from io object" do
  end

end
