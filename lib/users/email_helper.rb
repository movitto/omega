# Email Helper Utility
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'net/smtp'

module Users

  class EmailHelper
    include Singleton

    class << self
      attr_accessor :email_enabled
      attr_accessor :smtp_host
      attr_accessor :smtp_from_address
    end

    def initialize
    end

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
