# manufactured::start_mining tests
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'manufactured/rjr/mining'
require 'rjr/dispatcher'

module Manufactured::RJR
  describe "#start_mining", :rjr => true do
    include Omega::Server::DSL # for with_id below

    before(:each) do
      setup_manufactured :MINING_METHODS

      @miner = create(:valid_ship)
      @rs = create(:resource)
    end

    context "invalid ship id/type" do
      it "raises DataNotFound" do
        st = create(:valid_station)
        lambda {
          @s.start_mining 'invalid', @rs.id
        }.should raise_error(DataNotFound)
        lambda {
          @s.start_mining st.id, @rs.id
        }.should raise_error(DataNotFound)
      end
    end

    context "invalid resource id" do
      it "raises DataNotFound" do
        lambda{
          @s.start_mining @miner.id, 'invalid'
        }.should raise_error(DataNotFound)
      end
    end

    context "insufficient permissions (modify-miner)" do
      it "raise PermissionError" do
        lambda{
          @s.start_mining @miner.id, @rs.id
        }.should raise_error(PermissionError)
      end
    end

    context "suffiecient permissions (modify-miner)" do
      before(:each) do
        add_privilege @login_role, 'modify', "manufactured_entities"
      end

      it "does not raise PermissionError" do
        lambda{
          @s.start_mining @miner.id, @rs.id
        }.should_not raise_error
      end

      it "creates new mining command" do
        lambda {
          @s.start_mining @miner.id, @rs.id
        }.should change{@registry.entities.size}.by(1)
        @registry.entities.last.should be_an_instance_of(Commands::Mining)
        @registry.entities.last.ship.id.should == @miner.id
        @registry.entities.last.resource.id.should == @rs.id
      end

      it "returns miner" do
        r = @s.start_mining @miner.id, @rs.id
        r.should be_an_instance_of(Ship)
        r.id.should == @miner.id
      end
    end

  end # describe #start_mining

  describe "#dispatch_manufactured_rjr_mining" do
    it "adds manufactured::start_mining to dispatcher" do
      d = ::RJR::Dispatcher.new
      dispatch_manufactured_rjr_mining(d)
      d.handlers.keys.should include("manufactured::start_mining")
    end
  end

end #module Manufactured::RJR
