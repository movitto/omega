# dsl module tests
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

dir = File.dirname(__FILE__) 
require dir + '/spec_helper'

SIMRPC_SPEC = dir + '/../conf/motel-schema.xml'

describe "Motel::dsl" do

  it "should permit simple connections" do
    # setup simrpc server endpoint
    server = Motel::Server.new :schema_file => SIMRPC_SPEC

    # use dsl to connect to server and issue a few requests
    connect :schema_file => SIMRPC_SPEC do |client|
       loc = Location.new :id => 500
       client.create_location(loc).id.should == loc.id
       loc2 = client.get_location(loc.id)
       loc2.should_not be_nil
       loc2.id.should be(loc.id)
    end
  end

end
