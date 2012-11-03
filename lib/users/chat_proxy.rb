# Users module irc proxy
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'isaac/bot' # make sure to use isaac >= 0.3.0 (latest on rubygems.org is 0.2.6)

module Users

# Encapsulates message sent from user to chat server
class ChatMessage
  # Nick of chat user wh sent message
  attr_accessor :nick

  # Message sent by user to server
  attr_accessor :message

  # ChatMessage initializer
  # @param [Hash] args hash of options to initialize chat message with
  # @option args [String] :nick,'nick' nick to assign to the chat message
  # @option args [String] :message,'message' message to assign to the chat message
  def initialize(args = {})
    @nick    = args[:nick]    || args['nick']
    @message = args[:message] || args['message']
  end

  # Convert message to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:message => message, :nick => nick}
    }.to_json(*a)
  end

  # Create new message from json representation
  def self.json_create(o)
    user = new(o['data'])
    return user
  end
end

# Callback end user may register with server to invoke on new messages
class ChatCallback
  # [Callable] callable object to invoke on new messages
  attr_accessor :handler

  # ChatCallback initializer
  # @param [Hash] args hash of options to initialize callback with, currently used
  # @param [block] b block parameter to be set as handler
  def initialize(args = {}, &b)
    @handler = b
  end
end

# Proxies messages sent by the user to/from an irc server
class ChatProxy
  # [String] id of user sending/receiving messages
  attr_accessor :user

  # IRC server connection parameters
  attr_accessor :server, :port

  # Chatroom which to send/receive messages to/from
  attr_accessor :chatroom

  # Boolean indicating if client is connected to server
  attr_accessor :connected

  # Boolean indicating if client has joined the channel
  attr_accessor :inchannel

  # Queue of messages which to send to server on connecting
  attr_accessor :messages

  # Array of message callbacks registered with the server
  attr_accessor :callbacks

  class << self
    # @!group Config options

    # Default irc server to connect to
    # @!scope class
    attr_accessor :default_irc_server

    # Default irc port to connect to
    # @!scope class
    attr_accessor :default_irc_port

    # Default irc channel to join
    # @!scope class
    attr_accessor :default_irc_channel

    # @!endgroup
  end

  # Instantiate and return proxy for the specified user.
  #
  # Once instantiated the proxy will be stored locally and later
  # just returned on request.
  #
  # @param [String] user id of user to return proxy for
  # @return [Users::ChatProxy] chat proxy for user
  def self.proxy_for(user)
    @@proxies ||= {}
    @@proxies[user] = ChatProxy.new user unless @@proxies.has_key?(user)
    return @@proxies[user]
  end

  # ChatProxy initializer.
  #
  # Establishes connection to chat server and joins channel.
  #
  # @param [String] user id of user which to instantiate proxy for
  # @param [Hash] args hash of optional arguments to initialize proxy with
  # @option args [String] :server,'server' hostname of chat server to connect to
  # @option args [Integer] :port,'port' port of chat server to connect to
  # @option args [String] :channel,'channel' chat channel to join
  def initialize(user, args={})
    @user     = user
    @server   = args[:server ] || args['server']  || self.class.default_irc_server
    @port     = args[:port ]   || args['port']    || self.class.default_irc_port
    @chatroom = args[:channel] || args['channel'] || self.class.default_irc_channel

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
  end

  def connect
    return self if @connected
    @bot.start
    return self
  end

  # Register new callback with the proxy
  #
  # @param [ChatCallback] callback callback to register with the proxy
  def add_callback(callback)
    @callbacks << callback
  end

  # Send new message to chat server.
  #
  # If irc server connection hasn't been established, messages
  # will be queued until they can be sent.
  #
  # @param [String] message string message to send to server
  def proxy_message(message)
    if !@connected || !@inchannel
      @messages << message
    else
      @bot.msg(@chatroom, message)
    end
  end

end
end
