# Email Helper Utility
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'singleton'
require 'net/smtp'

EMAIL_ENABLED=true

module Users

  class EmailHelper
    include Singleton

    attr_reader :from_address

    def initialize
      # TODO make configurable
      @smtp_host    = 'localhost'
      @from_address = 'mo@morsi.org'
    end

    def send_email(to_address, message)
      if EMAIL_ENABLED
        Net::SMTP.start(@smtp_host) do |smtp|
          smtp.send_message message, @from_address,
                                      to_address
        end
      end
      nil
    end
  end
end
