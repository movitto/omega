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

describe ProxyNode do
  before(:each) do
    @dst = 'jsonrpc://localhost:8999'
  end

  after(:each) do
    ProxyNode.instance_variable_set(:@nodes, nil)
  end

  describe "#with_id" do
    it "returns node with the specified id" do
      n = ProxyNode.new(:id => 'foo', :dst => @dst)
      ProxyNode.instance_variable_set(:@nodes, [n])
      n1 = ProxyNode.with_id(n.id)
      n1.should == n
    end
  end

  describe "#initialize" do
    it "creates a new user to use with node" do
      n = ProxyNode.new :user_id => 'foo', :password => 'oof',
                        :dst => @dst
      n.user.id.should == 'foo'
      n.user.valid_login?('foo', 'oof')
    end

    it "creates a new node for the dst type" do
      n = ProxyNode.new :node_id => 'node1',
                        :dst => @dst
      n.rjr_node.should be_an_instance_of(RJR::Nodes::TCP)
      n.rjr_node.node_id.should == 'node1'
      n.dst.should == @dst

      @dst = 'omega-remote-queue'
      n = ProxyNode.new :dst => @dst
      n.rjr_node.should be_an_instance_of(RJR::Nodes::AMQP)
    end
  end

  describe "#login" do
    before(:each) do
      @n = ProxyNode.new :dst => @dst,
                         :user_id => 'user1'
      @s = Users::Session.new :id => 'session1'
    end

    it "invokes a users::login request against node" do
      @n.should_receive(:invoke).with('users::login', @n.user).
        and_return(@s)
      @n.login
    end

    it "sets session_id" do
      @n.should_receive(:invoke).and_return(@s)
      @n.login
      @n.rjr_node.message_headers['session_id'].should == @s.id
    end

    it "sets source_node" do
      @n.should_receive(:invoke).and_return(@s)
      @n.login
      @n.rjr_node.message_headers['source_node'].should == 'user1'
    end

    it "sets login_time" do
      @n.should_receive(:invoke).and_return(@s)
      @n.login
      @n.login_time.should_not be_nil
    end

    it "returns self" do
      @n.should_receive(:invoke).and_return(@s)
      @n.login.should == @n
    end
  end

  describe "#invoke" do
    it "invokes request against dst using node" do
      n = ProxyNode.new :dst => @dst
      n.rjr_node.should_receive(:invoke).with(@dst, 'foo')
      n.invoke 'foo'
    end
  end

  describe "#notify" do
    it "invokes notification against dst using node" do
      n = ProxyNode.new :dst => @dst
      n.rjr_node.should_receive(:notify).with(@dst, 'foo')
      n.notify 'foo'
    end
  end
end

end # module Server
end # module Omega
