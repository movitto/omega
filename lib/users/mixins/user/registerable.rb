# Users User Registerable Mixin
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

module Users

# Mixed into User, provides registration capabilities
module Registerable
  # Registration code, set on new user registration then deleted on confirmation.
  # If set the user has registered but hasn't confirmed their email yet
  attr_accessor :registration_code

  # Recaptcha challenge from new account request
  attr_accessor :recaptcha_challenge

  # Recaptcha response from new account request
  attr_accessor :recaptcha_response

  # Initialize default registration attributes /
  # registration attributes from arguments
  def registration_from_args(args)
    attr_from_args args,
      :registration_code   => -1, # nil registration code has special value
      :recaptcha_challenge => nil,
      :recaptcha_response  => nil
  end

  # Update registration attributes from specified user
  def update_registration(user)
    @registration_code =
      user.registration_code unless user.registration_code == -1
  end

  # Return registration attributes in json format
  def registration_json
    @secure_password ? {} : {:registration_code => registration_code}
  end
end # module Registerable
end # module Users
