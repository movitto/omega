# Omega Server Registry ProxiesEntities Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe ProxiesEntities do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)

      @e1 = {'foo' => 'bar'}
      @e2 = {'bar' => 'foo'}
    end

    describe "#proxies_for" do
      it "returns proxy entities for entities retrieved by the specified selector" do
        @e1 = {'foo' => 'bar'}
        @e2 = {'bar' => 'foo'}
        @registry << @e1
        @registry << @e2
        @e1.stub(:to_json).and_return('{}')
        @e2.stub(:to_json).and_return('{}')
        p = @registry.proxies_for { |e| true }
        p.should be_an_instance_of(Array)
        p.size.should == 2
        p.should == [@e1, @e2]
      end
    end

    describe "#proxy_for" do
      it "returns proxy entity for entity retrieved by the specified selector" do
        @registry << @e1
        @registry << @e2
        @e1.stub(:to_json).and_return('{}')
        @e2.stub(:to_json).and_return('{}')
        p = @registry.proxy_for { |e| true }
        #p.should be_an_instance_of(ProxyEntity) # TODO
        p.should == @e1
      end

      context "entity not found" do
        it "returns null" do
          p = @registry.proxy_for { |e| e == 1 }
          p.should be_nil
        end
      end

      it "sets registry on proxy entity" do
          e = Object.new
          e.stub(:to_json).and_return('{}')
          e.stub(:foobar) {
            lambda{
              @registry.safe_exec {}
            }.should raise_error(ThreadError)
          }
          @registry << e
          p = @registry.proxy_for { |e| true }
          p.foobar
      end
    end
  end # describe ProxiesEntities
end # module Registry
end # module Server
end # module Omega
