# users::register, users::confirm_register rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

module Users::RJR

# Register new user
register = proc { |user|
  # validate user
  raise ArgumentError,
    "user must be valid" unless user.is_a?(Users::User) && user.valid?

  # if recaptcha enabled, validate
  if Users::RJRAdapter.recaptcha_enabled
    # TODO move elsewhere, ensure client_ip is avaliable, recaptcha is valid
    recaptcha_response =
      Curl::Easy.http_post 'http://www.google.com/recaptcha/api/verify',
        Curl::PostField.content('privatekey', Users::RJR.recaptcha_priv_key),
        Curl::PostField.content('remoteip', @client_ip),
        Curl::PostField.content('challenge', user.recaptcha_challenge),
        Curl::PostField.content('response', user.recaptcha_response)
    recaptcha_response = recaptcha_response.body_str.split.first
    raise ArgumentError, "invalid recaptcha" if recaptcha_response != "true"
  end

  # generate random registraton code
  user.registration_code = Users::User.random_registration_code

  # create new user (raises err if id already taken)
  # FIXME node
  secure_user = node.invoke('users::create_entity', user)

  # create new email w/ users::confirm_register link
  message = <<MESSAGE_END
  From: #{EmailHelper.smtp_from_address}
  To: #{user.email}
  Subject: New Omega Account

  This is to inform you that your new omega account has been created. You
  will need to activate your registration code by navigating to the following
  link:

  #{Users::RJR.omega_url}confirm.html?rc=#{user.registration_code}

MESSAGE_END

  # send mail it to user
  # TODO if email is disabled just autoregister ?
  EmailHelper.instance.send_email user.email, message

  # return user (without password from this point)
  secure_user
}

# Confirm the registration code sent by email
confirm_register = proc { |registration_code|
  # retrieve user from registry
  user =
    Registry.instance.find { |e|
      e.registration_code == registration_code
    }.first

  # ensure user can be found
  raise DataNotFound, registration_code if user.nil?

  # safely nullify registration code
  user.registration_code = nil
  Registry.instance.update(user, &with_id(user.id))

  # return nil
  nil
}

REGISTER_METHODS = { :register => register,
                     :confirm_register => confirm_register }

end # module Users::RJR

def dispatch_register(dispatcher)
  m = Users::RJR::REGISTER_METHODS
  dispatcher.handle 'users::register',         &m[:users_register]
  dispatcher.handle 'users::confirm_register', &m[:users_confirm_register]
end