# motel/rjr/init tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'motel/rjr/init'

module Motel::RJR
  describe "#user_registry" do
    it "provides access to Users::RJR.registry" do
      rjr = Object.new.extend(Motel::RJR)
      rjr.user_registry.should == Motel::RJR.user_registry
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Motel::RJR)
      Motel::RJR.user_registry.should equal(rjr.user_registry)
    end
  end

  describe "#registry" do
    it "provides centralized registry" do
      rjr = Object.new.extend(Motel::RJR)
      rjr.registry.should be_an_instance_of(Registry)
      rjr.registry.should equal(rjr.registry)
    end

    it "is accessible on module" do
      rjr = Object.new.extend(Motel::RJR)
      Motel::RJR.registry.should equal(rjr.registry)
    end
  end

  describe "#reset" do
    it "clears motel registry" do
      Motel::RJR.registry << build(:location)
      Motel::RJR.registry.entities.size.should > 0
      Motel::RJR.reset
      Motel::RJR.registry.entities.size.should == 0
    end
  end

  describe "#dispatch_motel_rjr_init" do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      @d   = @n.dispatcher
      @rjr = Object.new.extend(Motel::RJR)
    end

    it "dispatches motel* in Motel::RJR environment" do
      dispatch_motel_rjr_init(@d)
      @d.environments[/motel::.*/].should  == Motel::RJR
    end

    it "adds motel rjr modules to dispatcher" do
      @d.should_receive(:add_module).with('motel/rjr/create')
      @d.should_receive(:add_module).with('motel/rjr/get')
      @d.should_receive(:add_module).with('motel/rjr/update')
      @d.should_receive(:add_module).with('motel/rjr/delete')
      @d.should_receive(:add_module).with('motel/rjr/track')
      @d.should_receive(:add_module).with('motel/rjr/state')
      dispatch_motel_rjr_init(@d)
    end
  end

end # module Users::RJR
