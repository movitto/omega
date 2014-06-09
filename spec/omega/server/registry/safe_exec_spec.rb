# Omega Server Registry SafeExec Mixin tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'

# test through registry inclusion
require 'omega/server/registry'

module Omega
module Server
module Registry
  describe SafeExec do
    before(:each) do
      @registry = Object.new
      @registry.extend(Registry)
    end

    describe "#safe_exec" do
      it "safely executes a block of code" do
        @registry.safe_exec { |entities|
          proc {
            @registry.safe_exec
          }.should raise_error(ThreadError, "deadlock; recursive locking")
        }
      end

      it "passes entities array to block" do
        eids1 = @registry.entities.collect { |e| e.id }
        eids2 = @registry.safe_exec { |entities|
                  entities.collect { |e| e.id } }
        eids1.should == eids2
      end
    end
  end # describe SafeExec
end # module Registry
end # module Server
end # module Omega
