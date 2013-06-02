# Stopped Callback tests
#
# Copyright (C) 2010-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/location'
require 'motel/callbacks/stopped'

module Motel::Callbacks
describe Stopped do
  describe "should_invoke?" do
    it "should return true" do
      m = Stopped.new
      m.should_invoke?(build(:location)).should be_true
    end
  end

  describe "#to_json" do
    it "returns callback in json format" do
      cb = Stopped.new :endpoint_id => 'baz'

      j = cb.to_json
      j.should include('"json_class":"Motel::Callbacks::Stopped"')
      j.should include('"endpoint_id":"baz"')
    end
  end

  describe "#json_create" do
    it "returns callback from json format" do
      j = '{"json_class":"Motel::Callbacks::Stopped","data":{"endpoint_id":"baz"}}'
      cb = JSON.parse(j)

      cb.class.should == Motel::Callbacks::Stopped
      cb.endpoint_id.should == "baz"
    end
  end

end # describe Stopped
end # module Motel::Callbacks
