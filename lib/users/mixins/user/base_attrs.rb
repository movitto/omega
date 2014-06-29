# Users User Base Attributes Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users

# Mixed into User, provides base attributes
module BaseAttrs
  # [String] unique string identifier of the user
  attr_accessor :id

  # [String] string email of the user
  attr_accessor :email

  # Time user account was created
  attr_accessor :created_at

  # Time user account was last modified
  attr_accessor :last_modified_at

  # Time user last logged in
  attr_accessor :last_login_at

  # [Boolean] indicating if this user is permenantly logged in
  attr_accessor :permenant

  # [Boolean] indicating if this user is a npc
  # TODO prohibit npcs from logging in?
  attr_accessor :npc

  # Initialize default base attributes / base attributes from arguments
  def base_attrs_from_args(args)
    attr_from_args args, :id        => nil,
                         :email     => nil,
                         :permenant => false,
                         :npc       => false,
                         :created_at       => nil,
                         :last_modified_at => nil,
                         :last_login_at    => nil
  end

  # Update base attributes from other user
  def update_base_attrs(user)
    @last_modified_at = Time.now
  end

  # Returns boolean indicating if email is valid
  def valid_email?
    !(self.email =~ (/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i)).nil?
  end

  # Return boolean indicating if id is valid
  def valid_id?
    id.is_a?(String) && !id.empty?
  end

  # Return boolean indicating if base attributes are valid
  def valid_base_attrs?
    valid_email? && valid_id?
  end

  # Return base attributes in json format
  def base_json
    {:id => id, :email => email, :permenant => permenant, :npc => npc,
     :created_at => created_at, :last_modified_at => last_modified_at,
     :last_login_at => last_login_at }
  end
end # module BaseAttrs
end # module Users
