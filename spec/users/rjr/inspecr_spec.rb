# users::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'users/rjr/inspect'
require 'rjr/dispatcher'

module Users::RJR
  describe "#status" do
    it "returns users.size"
    it "returns list of active session ids/user-ids that they belong to"
    it "returns roles along with privileges they entail and users that have them"
  end # describe "#status"

  describe "#dispatch_users_rjr_inspect" do
    it "adds users::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_users_rjr_inspect(d)
      d.handlers.keys.should include("users::status")
    end
  end

end #module Users::RJR
