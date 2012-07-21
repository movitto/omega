# Users session handling
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'motel/common'

module Users

class Session
  attr_accessor :id
  attr_accessor :user_id
  attr_accessor :login_time

  attr_accessor :user

  # TODO make configurable
  SESSION_EXPIRATION = 6000

  def initialize(args = {})
    @user       = args[:user]       || args['user']
    @user_id    = args[:user_id]    || args['user_id']
    @id         = args[:id]         || args['id']         || Motel::gen_uuid
    @login_time = args[:login_time] || args['login_time'] || Time.now

    @user = Users::Registry.instance.find(:id => @user_id) if !@user_id.nil? && @user.nil?
    @user_id = @user.id if !@user.nil? && @user_id.nil?
    
    @timeout_timestamp = Time.now
  end

  def timed_out?
    ct = Time.now
    return true if ct - @timeout_timestamp > SESSION_EXPIRATION

    @timeout_timestamp = ct
    return false
  end

  def to_s
    "session-#{@id}(#{@user})"
  end

  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => {:user_id => user_id, :id => id, :login_time => login_time}
    }.to_json(*a)
  end

  def self.json_create(o)
    user = new(o['data'])
    return user
  end


end

end
