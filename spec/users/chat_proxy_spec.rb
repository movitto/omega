# chat_proxy module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

describe Users::ChatMessage do
  it "should be convertable to json" do
    msg = Users::ChatMessage.new :nick => 'mmorsi', :message => 'foobar'

    j = msg.to_json
    j.should include('"json_class":"Users::ChatMessage"')
    j.should include('"message":"foobar"')
    j.should include('"nick":"mmorsi"')
  end

  it "should be convertable from json" do
    j = '{"json_class":"Users::ChatMessage","data":{"message":"foobar","nick":"mmorsi"}}'
    msg = JSON.parse(j)

    msg.class.should == Users::ChatMessage
    msg.nick.should == 'mmorsi'
    msg.message.should == 'foobar'
  end
end

describe Users::ChatProxy do
  before(:all) do
    @proxy1 = Users::ChatProxy.proxy_for 'peromeusetes1'
    @proxy1.connect

    @proxy2 = Users::ChatProxy.proxy_for 'peromeusetes2'
    @proxy2.proxy_message("pre-message")
    @proxy2.connect
    sleep 20
  end

  #it "should accept config options" do
  #end

  it "should return proxy for the specified user" do
    proxy = Users::ChatProxy.proxy_for 'omega_users_test'

    proxy.class.should == Users::ChatProxy
    proxy.user.should == 'omega_users_test'

    proxy2 = Users::ChatProxy.proxy_for 'omega_users_test'
    proxy2.should == proxy
  end

  it "should clear proxies" do
    proxy = Users::ChatProxy.proxy_for 'omega_users_test'
    Users::ChatProxy.class_variable_get(:@@proxies)['omega_users_test'].should_not be_nil

    Users::ChatProxy.clear
    Users::ChatProxy.class_variable_get(:@@proxies)['omega_users_test'].should be_nil
  end

  it "should cache all messages sent" do
    proxy = Users::ChatProxy.proxy_for 'omega_users_test'
    proxy.proxy_message "omega test"
    proxy.messages.should include('omega test')
  end

  it "should connect to chat server" do
    @proxy1.connected.should be_true
    @proxy2.connected.should be_true
    #@proxy.instance_variable_get(:@bot) # TODO test isaac irc / event machine connection
  end

  it "should send chat messages" do
    proxy = Users::ChatProxy.proxy_for 'omega_users_test'

    # stub out a simple mock irc server
    messages = []
    bot = stub(Object)
    bot.should_receive(:start)
    bot.stub(:msg) { |ch,m| messages << m }
    proxy.instance_variable_set(:@bot, bot)
    proxy.connect

    # XXX needed so proxy passes messages through to bot
    proxy.connected = true
    proxy.inchannel = true

    proxy.proxy_message "foobar"
    messages.should include("foobar")
    proxy.messages.should include("foobar")
  end

  it "should send chat messages queued before connection" do
    @proxy2.messages.should include("pre-message")
  end

  it "should receive chat messages" do
    #@proxy1.messages.should include("pre-message")

    invoked = false
    cb = Users::ChatCallback.new { |m| m.message.should == "post message" ; invoked = true}
    Users::ChatProxy.proxy_for(@proxy1.user).add_callback(cb)

    @proxy2.proxy_message("post message")
    sleep 1
    invoked.should be_true
  end
end
