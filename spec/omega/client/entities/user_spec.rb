# client user module tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/user'

module Omega::Client
  describe User do

    describe "#login" do
      it "logs the specified user in"
      it "sets session_id message header on node"
    end

  end # describe User
end # module Omega::Client
