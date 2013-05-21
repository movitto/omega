# users::register, users::confirm_register rjr definitions
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

users_register = proc { |user|
  raise ArgumentError, "user must be an instance of Users::User" unless user.is_a?(Users::User)

  # validate email format, user isn't already taken
  raise ArgumentError, "invalid user email"    unless user.valid_email?
  raise ArgumentError, "user id already taken" unless Users::Registry.instance.find(:id => user.id).empty?
  raise ArgumentError, "valid username and password is required"  unless user.id.is_a?(String) && user.password.is_a?(String) && user.id != "" && user.password != ""

  if Users::RJRAdapter.recaptcha_enabled
    # TODO ensure node type isn't amqp so that client_ip is available ?
    # ensure recaptcha is valid
    recaptcha_response = Curl::Easy.http_post 'http://www.google.com/recaptcha/api/verify',
                                        Curl::PostField.content('privatekey', Users::RJRAdapter.recaptcha_priv_key),
                                        Curl::PostField.content('remoteip', @client_ip),
                                        Curl::PostField.content('challenge', user.recaptcha_challenge),
                                        Curl::PostField.content('response', user.recaptcha_response)
    recaptcha_response = recaptcha_response.body_str.split.first
    raise ArgumentError, "invalid recaptcha" if recaptcha_response != "true"
  end

  # generate random registraton code
  user.registration_code = Users::User.random_registration_code

  # clear alliances
  user.alliances = []

  # create new user
  secure_user = @@local_node.invoke_request('users::create_entity', user)


  # send users::confirm_register link via email
  message = <<MESSAGE_END
  From: #{EmailHelper.smtp_from_address}
  To: #{user.email}
  Subject: New Omega Account

  This is to inform you that your new omega account has been created. You
  will need to activate your registration code by navigating to the following
  link:

  #{Users::RJRAdapter.omega_url}confirm.html?rc=#{user.registration_code}

MESSAGE_END
  EmailHelper.instance.send_email user.email, message
  # TODO if email is disabled just autoregister ?

  secure_user
}

users_confirm_register = proc { |registration_code|
  user = Users::Registry.instance.find(:registration_code => registration_code).first
  raise Omega::DataNotFound, "user specified by registration code #{registration_code} not found" if user.nil?

  Users::Registry.instance.safely_run {
    user.registration_code = nil
  }

  nil
}

def dispatch_register(dispatcher)
  dispatcher.handle 'users::register', &users_register
  dispatcher.handle 'users::confirm_register', &users_confirm_register
end
