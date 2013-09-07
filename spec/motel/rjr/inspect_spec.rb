# motel::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/inspect'
require 'rjr/dispatcher'

module Motel::RJR
  describe "#status" do
    it "returns registry.running?"
    it "returns registry.entities.size"
    it "returns map of movement strategies to number of locations with them"
  end # describe "#status"

  describe "#dispatch_motel_rjr_inspect" do
    it "adds motel::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_motel_rjr_inspect(d)
      d.handlers.keys.should include("motel::status")
    end
  end

end #module Users::RJR
