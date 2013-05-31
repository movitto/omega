# chat_proxy module tests
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

module Users
describe ChatMessage do
  describe "#to_json" do
    it "returns message in json format" do
      msg = ChatMessage.new :nick => 'mmorsi', :message => 'foobar'

      j = msg.to_json
      j.should include('"json_class":"Users::ChatMessage"')
      j.should include('"message":"foobar"')
      j.should include('"nick":"mmorsi"')
    end
  end

  describe "#json_create" do
    it "return message from json format" do
      j = '{"json_class":"Users::ChatMessage","data":{"message":"foobar","nick":"mmorsi"}}'
      msg = JSON.parse(j)

      msg.class.should == Users::ChatMessage
      msg.nick.should == 'mmorsi'
      msg.message.should == 'foobar'
    end
  end

end # describe ChatMessage

describe ChatProxy do
  # FIXME mock server replies instead of actually connecting to server
  before(:all) do
    @proxy1 = ChatProxy.proxy_for 'peromeusetes1'
    @proxy1.connect

    @proxy2 = ChatProxy.proxy_for 'peromeusetes2'
    @proxy2.proxy_message("pre-message")
    @proxy2.connect
    sleep 20 # XXX
  end

  after(:each) do
    Users::ChatProxy.clear
  end

  #it "should accept config options" do
  #end

  describe "connected" do
    it "returns bool indicating connection to server" do
      @proxy1.connected.should be_true
      @proxy2.connected.should be_true
      #@proxy.instance_variable_get(:@bot) # TODO test isaac irc / event machine connection
    end
  end

  describe "#proxy_for" do
    it "returns proxy for user" do
      proxy = Users::ChatProxy.proxy_for 'omega_users_test'

      proxy.class.should == Users::ChatProxy
      proxy.user.should == 'omega_users_test'
    end

    it "returns same proxy for user" do
      proxy = Users::ChatProxy.proxy_for 'omega_users_test'
      proxy2 = Users::ChatProxy.proxy_for 'omega_users_test'
      proxy2.should == proxy
    end
  end

  describe "#clear" do
    it "clears proxies" do
      proxy = Users::ChatProxy.proxy_for 'omega_users_test'
      Users::ChatProxy.class_variable_get(:@@proxies)['omega_users_test'].should_not be_nil

      Users::ChatProxy.clear
      Users::ChatProxy.class_variable_get(:@@proxies)['omega_users_test'].should be_nil
    end
  end

  describe "#proxy_message" do
    it "caches messages" do
      proxy = Users::ChatProxy.proxy_for 'omega_users_test'
      proxy.proxy_message "omega test"
      proxy.messages.should include('omega test')
    end

    it "sends messages" do
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

    it "sends messages queued before connection" do
      @proxy2.messages.should include("pre-message")
    end
  end

  describe "#add_callback" do
    it "registers new callback"
  end

  it "invokes callbacks on message received" do
    invoked = false
    cb = Users::ChatCallback.new { |m| m.message.should == "post message" ; invoked = true}
    Users::ChatProxy.proxy_for(@proxy1.user).add_callback(cb)

    @proxy2.proxy_message("post message")
    sleep 1
    invoked.should be_true
  end

end # describe ChatProxy
end # module Users
