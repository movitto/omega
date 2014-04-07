# Omega Server subsystem DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/subsystem'

require 'manufactured/events'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  describe "#subsystem" do
    it "returns subsystem request is running in" do
      should_receive(:rjr_env).and_return(Omega::Server)
      subsystem.should == Omega
    end
  end

  describe "#subsystem_event?" do
    context "specified event is found in subsystem events" do
      it "returns true" do
        event = Manufactured::Events.constants.first
        event = Manufactured::Events.const_get(event)
        should_receive(:subsystem).and_return(Manufactured)
        subsystem_event?(event::TYPE).should be_true
      end
    end

    context "specified event is not found in subsystem events" do
      it "returns false" do
        should_receive(:subsystem).and_return(Manufactured)
        subsystem_event?('invalid').should be_false
      end
    end
  end

  describe "#subsystem_entity?" do
    context "entity is defined under specified subsystem" do
      it "returns true" do
        subsystem_entity?(Manufactured::Ship.new,
                          Manufactured).should be_true
        subsystem_entity?(Cosmos::Entities::Planet.new,
                          Cosmos::Entities).should be_true
        subsystem_entity?(Cosmos::Entities::Planet.new,
                          Cosmos).should be_true
      end
    end

    context "entity is not defined under specified subsystem" do
      it "returns false" do
        subsystem_entity?(Cosmos::Entities::Planet.new,
                          Manufactured).should be_false
      end
    end

    it "defaults to current subsystem" do
      should_receive(:subsystem).twice.and_return(Manufactured)
      subsystem_entity?(Manufactured::Ship.new).should be_true
      subsystem_entity?(Cosmos::Entities::Planet.new).should be_false
    end
  end

  describe "#cosmos_entity?" do
    context "entity is under Cosmos::Entities" do
      it "returns true" do
        cosmos_entity?(Cosmos::Entities::Galaxy.new).should be_true
      end
    end

    context "entity is not under Cosmos::Entities" do
      it "returns false" do
        cosmos_entity?(Cosmos::Resource.new).should be_false
      end
    end
  end

end # describe DSL
end # module Server
end # module Omega

