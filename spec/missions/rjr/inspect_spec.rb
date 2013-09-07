# missions::status test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'missions/rjr/inspect'
require 'rjr/dispatcher'

module Missions::RJR
  describe "#status" do
    it "returns registry.running?"
    it "returns events.size"
    it "returns missions.size"
    it "returns active missions.size"
    it "returns victorious missions.size"
    it "returns failed missions.size"
  end # describe "#status"

  describe "#dispatch_missions_rjr_inspect" do
    it "adds missions::status to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_missions_rjr_inspect(d)
      d.handlers.keys.should include("missions::status")
    end
  end

end #module Users::RJR
