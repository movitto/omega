# Omega Server Command Helpers tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/command_helpers'

module Omega
module Server
describe CommandHelpers do
  before(:each) do
    @ch = OpenStruct.new.extend(CommandHelpers)
    @ch.registry = double()
    @ch.node = double()
  end

  describe "#update_registry" do
    it "updates registry entity" do
      e = Object.new
      @ch.registry.should_receive(:update).
                   with(e) # TODO test selector
      @ch.update_registry(e)
    end
  end

  describe "retrieve" do
    it "retrieves registry entity" do
      e = Object.new
      @ch.registry.should_receive(:entity) # TODO test selector
      @ch.retrieve(e)
    end
  end

  describe "run callbacks" do
    it "runs callbacks on registry entity" do
      e1 = double(:id => 42)
      e2 = double(:id => 43)
      @ch.registry.should_receive(:safe_exec).and_yield([e1,e2])

      e1.should_receive(:run_callbacks).with(:abc)
      entity = double(:id => 42)
      @ch.run_callbacks entity, :abc
    end
  end

  describe "#invoke" do
    it "proxies node.invoke" do
      @ch.node.should_receive(:invoke).with(42)
      @ch.invoke 42
    end
  end
end # describe CommandHelpers
end # module Server
end # module Omega
