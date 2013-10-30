# manufactured::admin test
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/admin'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#admin::set", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :ADMIN_METHODS
    end

    it "updates the specified registry entity" do
      e = create(:valid_ship)
      e.hp = 0
      Manufactured::RJR.registry.should_receive(:update).with(e).
                                 and_call_original
      @s.set e

      Manufactured::RJR.registry.entity(&with_id(e.id)).hp.should == 0
    end
  end # describe "#admin::set"

  describe "#admin::run_callbacks", :rjr => true do
    before(:each) do
      setup_manufactured :ADMIN_METHODS
    end

    it "runs callbacks on the registry entity specified by id" do
      e = create(:valid_ship)
      re = Manufactured::RJR.registry.safe_exec { |es| es.find { |e| e.id == e.id }}
      re.should_receive(:run_callbacks).with(42)
      @s.run_callbacks e.id, 42
    end
  end # describe "#admin::run_callbacks"

  describe "#dispatch_manufactured_rjr_admin" do
    it "adds manufactured::admin::set to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_admin(d)
      d.handlers.keys.should include("manufactured::admin::set")
    end

    it "adds manufactured::admin::run_callbacks to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_admin(d)
      d.handlers.keys.should include("manufactured::admin::run_callbacks")
    end
  end

end #module Users::RJR
