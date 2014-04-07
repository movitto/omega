# manufactured::subscribe_to helpers specs
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/subscribe_to/helpers'

module Manufactured::RJR
  describe "subsystem_entity?" do
    include Manufactured::RJR

    context "ship or station" do
      it "returns true" do
        subsystem_entity?(Manufactured::Ship.new).should be_true
      end
    end

    context "anything else" do
      it "returns false" do
        subsystem_entity?(42).should be_false
      end
    end
  end

  describe "#cosmos_entity?" do
    include Manufactured::RJR

    context "Cosmos::Entity instance" do
      it "returns true" do
        cosmos_entity?(Cosmos::Entities::Galaxy.new).should be_true
      end
    end

    context "anything else" do
      it "returns false" do
        cosmos_entity?(42).should be_false
      end
    end
  end
end # module Manufactured::RJR
