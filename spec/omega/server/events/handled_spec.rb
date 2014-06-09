# Omega Server Handled Event tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/events/handled'

module Omega
module Server
  describe HandledEvent do
    it "adds handle_event to event handlers" do
      event = HandledEvent.new
      event.handlers.size.should == 1
      event.should_receive(:handle_event)
      event.invoke
    end

    describe "#handlers_json" do
      it "excludes handle_event from handlers" do
        event = HandledEvent.new
        event.handlers_json.should == {:handlers => []}
      end
    end
  end
end # module Server
end # module Omega
