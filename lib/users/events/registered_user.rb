# Users Registered User Event definition
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/server/event'

module Users
module Events

# Spawned by the local users subsystem
class RegisteredUser < Omega::Server::Event
  ID = 'registered_user'

  # Handle to user that was registered
  attr_accessor :user

  # RegisteredUser Event intializer
  def initialize(user=nil)
    @user = user
    super(:id => ID)
  end

  # Convert event to json representation and return it
  def to_json(*a)
    {
      'json_class' => self.class.name,
      'data'       => @user
    }.to_json(*a)
  end

end # class RegisteredUser
end # module Events
end # module Users
