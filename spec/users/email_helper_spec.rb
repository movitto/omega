# email helper tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/email_helper'

module Users::RJR
  describe EmailHelper do
    describe "#send_email" do
      context "email is disabled" do
        it "does not send email" do
          EmailHelper.email_enabled = false
          Net::SMTP.should_not_receive(:start)
          EmailHelper.instance.send_email("t@o", "msg")
        end
      end

      context "email is enabled" do
        it "sends email" do
          EmailHelper.smtp_host = 'foobar'
          EmailHelper.smtp_from_address = 'f@rom'
          EmailHelper.email_enabled = true
          smtp = double(Object)
          smtp.should_receive(:send_message).
                 with("msg", "f@rom", "t@o")
          Net::SMTP.should_receive(:start).with('foobar').and_yield(smtp)
          EmailHelper.instance.send_email("t@o", "msg")
        end
      end
    end
  end
end
