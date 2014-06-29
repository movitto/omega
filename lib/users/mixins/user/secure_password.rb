# Users User SecurePassword Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'users/password_helper'

module Users

# Mixed into User, provides secure password capabilities
module SecurePassword
  # [String] user password (encrypted if secure_password is enabled)
  attr_reader :password

  # Set user password. Will be encrypted if secure_pasword is enabled
  def password=(v)
    @password = v
    if @secure_password
      @password = PasswordHelper.update(@password)
    end
  end

  # Boolean indicating if we should take additional steps to secure pass
  attr_reader :secure_password

  # Set password security on / off
  #
  # FIXME since password helper uses one way encryption setting to
  # false would have no effect, and setting to true multiple times
  # would render the password invalid. Need to fix this.
  def secure_password=(v)
    v = @secure_password unless [true, false].include?(v)
    @secure_password = v
    if @secure_password
      # encrypt password w/ salt
      @password = PasswordHelper.update(@password)
    end
  end

  # Initialize default password / password from arguments
  def password_from_args(args)
    attr_from_args args, :password        => nil,
                         :secure_password => false
  end

  # Update password from specified user
  def update_password(user)
    if user.password
      @password = user.password

      # XXX: ensure password is salted after updating if necessary
      self.secure_password = @secure_password
    end
  end

  # Return boolean indicating if password is valid
  def valid_password?
    password.is_a?(String) && !password.empty?
  end

  # Returns boolean indicating if password is valid
  def password_matches?(password)
    @secure_password ? PasswordHelper.check(password, self.password) :
                       password == self.password
  end

  # Return password in json format
  def password_json
    @secure_password ? {} : {:password => password}
  end
end # module HasRoles
end # module Users
