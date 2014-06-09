# Omega Server node DSL tests
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/server/dsl/node'

require 'rjr/nodes/local'
require 'rjr/nodes/tcp'

module Omega
module Server
describe DSL do
  include Omega::Server::DSL

  before(:each) do
    @rjr_node = @n
  end

  describe "#is_node?" do
    context "node is of specified type" do
      it "returns true" do
        is_node?(RJR::Nodes::Local).should be_true
      end
    end

    context "node is not of specified type" do
      it "returns false" do
        is_node?(RJR::Nodes::TCP).should be_false
      end
    end
  end
  
  describe "#persistent_transport?" do
    context "rjr node is persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(true)
      end

      it "returns true" do
        persistent_transport?.should be_true
      end
    end

    context "rjr node is not persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(false)
      end

      it "returns false" do
        persistent_transport?.should be_false
      end
    end
  end

  describe "#require_persistent_transport!" do
    context "transport is persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(true)
      end

      it "does not raise error" do
        lambda {
          require_persistent_transport!
        }.should_not raise_error
      end
    end

    context "transport is not persistent" do
      before(:each) do
        @rjr_node = Object.new
        @rjr_node.stub(:persistent?).and_return(false)
      end

      it "raises OperationError" do
        lambda {
          require_persistent_transport!
        }.should raise_error(OperationError)
      end
    end
  end

  describe "#from_valid_source?" do
    before(:each) do
      @rjr_headers = {}
    end

    context "source_node rjr header is a non empty string" do
      it "returns true" do
        @rjr_headers['source_node'] = 'node-user1'
        from_valid_source?.should be_true
      end
    end

    context "source_node rjr header is anything else" do
      it "returns false" do
        from_valid_source?.should be_false

        @rjr_headers['source_node'] = ''
        from_valid_source?.should be_false

        @rjr_headers['source_node'] = 42
        from_valid_source?.should be_false
      end
    end
  end

  describe "#require_valid_source!" do
    before(:each) do
      @rjr_headers = {}
    end

    context "valid source node" do
      it "does not raise error" do
        @rjr_headers['source_node'] = 'node-user1'
        lambda {
          require_valid_source!
        }.should_not raise_error
      end
    end

    context "invalid source node" do
      it "raises PermissionError" do
        lambda {
          require_valid_source!
        }.should raise_error(PermissionError)
      end
    end
  end
end # describe DSL
end # module Server
end # module Omega
