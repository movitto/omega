# Omega Server Proxy tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/proxy'

module Omega
module Server

describe ProxyEntity do
  before(:each) do
    @e = Motel::Location.new
    @r = Object.new
    @r.extend(Registry)
    @p = ProxyEntity.new @e, @r
  end

  it "proxies all methods to entity" do
    @e.should_receive(:foobar).with(5)
    @p.foobar 5
  end

  it "protects entity from concurrent access" do
    @e.stub(:foobar) { @p.foobar 5 }
    lambda {
      @p.foobar 5
    }.should raise_error(ThreadError)
  end

  it "raises updated event" do
    @e.should_receive(:foobar)
    @r.should_receive(:raise_event).
       with{ |*a|
         a[0].should == :updated
         a[1].should == @e
         a[2].should be_an_instance_of(Motel::Location)
         a[2].id.should == @e.id
       }
    @p.foobar 5
  end

  it "returns original return value" do
    @e.should_receive(:foobar).and_return(42)
    @p.foobar.should == 42
  end
end # describe ProxyEntity

end # module Server
end # module Omega
