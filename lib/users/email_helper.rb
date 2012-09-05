# Email Helper Utility
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'net/smtp'

module Users

  # Helper singleton class to assist in sending emails.
  class EmailHelper
    include Singleton

    class << self
      # @!group Config options

      # Boolean toggling email subsystem
      # @!scope class
      attr_accessor :email_enabled

      # String smtp host to connect to
      # @!scope class
      attr_accessor :smtp_host

      # From address to set on outgoing smtp messages
      # @!scope class
      attr_accessor :smtp_from_address

      # @!endgroup
    end

    def initialize
    end

    # Send message to specified address
    #
    # @param [String] to_address e-mail address to send message to
    # @param [String] message body of message to email
    def send_email(to_address, message)
      if self.class.email_enabled
        Net::SMTP.start(self.class.smtp_host) do |smtp|
          smtp.send_message message, self.class.smtp_from_address, to_address
        end
      end
      nil
    end
  end
end
