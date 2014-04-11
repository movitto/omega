# Omega Client HasCargo Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/has_cargo'

# Test data used in this module
module OmegaTest
  class HasCargo
    include Omega::Client::Trackable
    include Omega::Client::TrackEvents
    include Omega::Client::HasCargo
  end
end

module Omega::Client
  describe HasCargo, :rjr => true do
    before(:each) do
      OmegaTest::HasCargo.node.rjr_node = @n
      @h = OmegaTest::HasCargo.new

      @h.entity = create(:valid_ship)
      @h.entity.add_resource create(:resource, :id => 'gem-diamond', :quantity => 10)
      @h.entity.add_resource create(:resource, :id => 'gem-ruby',    :quantity => 15)
      setup_manufactured(nil, reload_super_admin)

      @t = create(:valid_ship)
    end

    describe "#transfer_all_to" do
      it "invokes transfer with each local resource" do
        @h.entity.resources.each { |r|
          @h.should_receive(:transfer).with(r, @t)
        }
        @h.transfer_all_to(@t)
      end
    end

    describe "#transfer" do
      it "invokes manufactured::transfer_resource" do
        @h.node.should_receive(:invoke).
                with('manufactured::transfer_resource',
                     @h.entity.id, @t.id, @h.resources.first).
                and_return([@h, @t])
        @h.transfer @h.resources.first, @t
      end

      it "updates source/target entities" do
        @h.node.should_receive(:invoke).and_return([:foo, :bar])
        @h.transfer @h.resources.first, @t
        @h.entity.should == :foo
        #@t.entity.should == :bar
      end

      it "raises transfered event" do
        @h.node.should_receive(:invoke).and_return([@h, @t])
        @h.should_receive(:raise_event).with(:transferred_to, @t, @h.resources.first)
        @h.transfer @h.resources.first, @t
      end

      #it "raises received event"
    end
  end # describe HasCargo
end # module Omega::Client
