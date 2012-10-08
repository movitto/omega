# Users session handling
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'motel/common'

module Users

# Sessions are created on user logins and exist until the user
# logs out or the expiration time passes between activies.
#
# Upon logging in, the user may set the session id as a json-rpc/rjr
# header and pass it to the {Users::Registry} on subsequent requests
# to determine in the logged in user has the necessary privileges to
# perform the requested operations.
class Session
  # Unique identifier of the session
  attr_accessor :id

  # ID of the user which this session belongs to
  attr_accessor :user_id

  # Time the session was established
  attr_accessor :login_time

  # Handle to the user which established the session
  attr_accessor :user

  # Number of seconds which inactivity is allowed before invalidating the session.
  #
  # TODO make configurable
  SESSION_EXPIRATION = 6000

  # Session initializer
  # @param [Hash] args hash of options to initialize the session with
  # @option args [Users::User] :user,'user' user owner of the session
  # @option args [String] :user_id,'user_id' id of user owner of the session
  # @option args [String] :id,'id' id to assign to session
  # @option args [Time] :login_time,'login_time' time session was established
  def initialize(args = {})
    @user       = args[:user]       || args['user']
    @user_id    = args[:user_id]    || args['user_id']
    @id         = args[:id]         || args['id']         || Motel::gen_uuid
    @login_time = args[:login_time] || args['login_time'] || Time.now

    @user = Users::Registry.instance.find(:id => @user_id) if !@user_id.nil? && @user.nil?
    @user_id = @user.id if !@user.nil? && @user_id.nil?
    
    @timeout_timestamp = Time.now
  end

  # Return boolean indicating if this session is no longer valid.
  #
  # Returns true if {SESSION_EXPIRATION} seconds have passed since
  # the session was created or this method was last invoked, else
  # return false.
  #
  # @return [true,false] if the session has timed out or not
  def timed_out?
    ct = Time.now
    return true if ct - @timeout_timestamp > SESSION_EXPIRATION &&
                   !@user.permenant

    @timeout_timestamp = ct
    return false
  end

  # Convert session to human readable string and return it
  def to_s
    "session-#{@id}(#{@user})"
  end

  # Convert session to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:user_id => user_id, :id => id, :login_time => login_time}
    }.to_json(*a)
  end

  # Create new session from json representation
  def self.json_create(o)
    session = new(o['data'])
    return session
  end


end

end
