# manufactured::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/inspect'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#status" do
    it "returns registry.running?"
    it "returns ships.size"
    it "returns stations.size"
    it "returns all commands"
  end # describe "#status"

  describe "#dispatch_manufactured_rjr_inspect" do
    it "adds manufactured::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_inspect(d)
      d.handlers.keys.should include("manufactured::status")
    end
  end

end #module Users::RJR
