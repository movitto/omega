# Omega Server Registry HasState Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe HasState do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
    end

    describe "#save" do
      it "stores entities in json in io object" do
        @registry << OmegaTest::ServerEntity.new(:id => 1)
        @registry << OmegaTest::ServerEntity.new(:id => 2)

        sio = StringIO.new
        @registry.save(sio)
        s = sio.string

        s.should include('"id":1')
        s.should include('"id":2')
        s.should include('"json_class":"OmegaTest::ServerEntity"')
      end

      it "skips entity classes marked to exclude" do
        @registry.backup_excludes = [Command]
        @registry << Command.new(:id => 'cid')
        @registry << OmegaTest::ServerEntity.new(:id => '1')

        sio = StringIO.new
        @registry.save(sio)
        s = sio.string

        s.should include('"json_class":"OmegaTest::ServerEntity"')
        s.should_not include('"json_class":"Omega::Server::Command"')
        s.should include('"id":"1"')
        s.should_not include('"id":"cid"')
      end
    end

    describe "#restore" do
      it "retrieves entities from json in io object" do
        s = '{"json_class":"OmegaTest::ServerEntity","data":{"id":1,"val":null}}'+"\n"+
            '{"json_class":"OmegaTest::ServerEntity","data":{"id":2,"val":null}}'

        sio = StringIO.new
        sio.string = s

        @registry.restore s
        @registry.entities.size.should == 2
        @registry.entities.first.should == OmegaTest::ServerEntity.new(:id => 1, :val => nil)
      end
    end
  end # describe HasState
end # module Registry
end # module Server
end # module Omega
