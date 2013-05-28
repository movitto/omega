# Omega Server DSL tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl'

module Omega
module Server
describe DSL do
  
  describe "#login" do
    it "invokes remote login"
    it "returns session"
    it "sets node session_id"
    it "stores node locally"
  end

  describe "#is_node?" do
    context "node is of specified type" do
      it "returns true"
    end

    context "node is not of specified type" do
      it "returns false"
    end
  end

  describe "#require_privilege" do
    context "user has privilege" do
      it "does not throw error"
    end

    context "user does not have privilege" do
      it "throws error"
    end
  end

  describe "#check_privilege" do
    context "user has privilege" do
      it "returns true"
    end

    context "user does not have privilege" do
      it "return false"
    end
  end

  describe "#filter_properites" do
    it "returns new instance of data type"
    it "copies whitelisted attributes from original instance to new one"
    it "does not copy attributes not on the whitelist"
  end

  describe "#filter_from_args" do
    it "generates filter from args list"

    context "arg specifies invalid filter id" do
      it "throws a ValidationError"
    end
  end

end

end # module Server
end # module Omega
