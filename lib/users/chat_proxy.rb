# Users module irc proxy
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'isaac/bot' # make sure to use isaac >= 0.3.0 (latest on rubygems.org is 0.2.6)

module Users

class ChatMessage
  attr_accessor :nick
  attr_accessor :message

  def initialize(args = {})
    @nick    = args[:nick]    || args['nick']
    @message = args[:message] || args['message']
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:message => message, :nick => nick}
    }.to_json(*a)
  end

  def self.json_create(o)
    user = new(o['data'])
    return user
  end
end

class ChatCallback
  attr_accessor :handler

  def initialize(args = {}, &b)
    @handler = b
  end
end

class ChatProxy
  attr_accessor :user, :server, :port, :chatroom, :connected, :inchannel, :messages, :callbacks

  def self.proxy_for(user)
    @@proxies ||= {}
    @@proxies[user] = ChatProxy.new user unless @@proxies.has_key?(user)
    return @@proxies[user]
  end

  def initialize(user, args={})
    @user     = user
    @server   = args[:server ] || args['server']  || 'irc.freenode.net'
    @port     = args[:port ]   || args['port']    || 6667
    @chatroom = args[:channel] || args['channel'] || '#unv-chat'

    @inchannel = false
    @connected = false
    @messages  = []
    @callbacks = []

    @bot = Isaac::Bot.new do
      on :connect do
        proxy = ChatProxy.proxy_for(user)
        join proxy.chatroom
        proxy.connected = true
      end
      on :join do
        proxy = ChatProxy.proxy_for(user)
        proxy.messages.each { |pm|
          msg proxy.chatroom, pm
        }
        proxy.inchannel = true
      end
      on :channel do
        proxy = ChatProxy.proxy_for(user)
        proxy.callbacks.each { |c|
          cm = ChatMessage.new :message => message, :nick => nick
          c.handler.call cm
        }
      end
    end
    # TODO set timeout
    @bot.config.nick    = @user
    @bot.config.server  = @server
    @bot.config.port    = @port
    @bot.config.verbose = true
    @bot.start
  end

  def add_callback(callback)
    @callbacks << callback
  end

  def proxy_message(message)
    if !@connected || !@inchannel
      @messages << message
    else
      @bot.msg(@chatroom, message)
    end
  end

end
end
