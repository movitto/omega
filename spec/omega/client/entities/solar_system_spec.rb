# Omega Client Solar System Tests
#
# Copyright (C) 2012-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'spec_helper'
require 'omega/client/entities/solar_system'

module Omega::Client
  describe SolarSystem, :rjr => true do
    before(:each) do
      Omega::Client::SolarSystem.node.rjr_node = @n

      setup_manufactured(nil, reload_super_admin)
    end

    describe "#jump_gates" do
      it "caches jump gate endpoints" do
        rsys = Cosmos::Entities::SolarSystem.new :id => 'rsys'
        sys = Cosmos::Entities::SolarSystem.new :children =>
                [Cosmos::Entities::JumpGate.new(:id => 'jg1', :endpoint => rsys),
                 Cosmos::Entities::JumpGate.new(:id => 'jg2', :endpoint_id => 'rem_sys')]

        s = Omega::Client::SolarSystem.new
        s.entity = sys
        SolarSystem.should_receive(:cached).with('rem_sys').once
        SolarSystem.should_not_receive(:cached).with('rsys')
        s.jump_gates.should == s.jump_gates
      end
    end

    describe "#asteroids" do
      it "retrieves asteroid resources" do
        sys  = Cosmos::Entities::SolarSystem.new :children =>
                [Cosmos::Entities::Asteroid.new(:id => 'ast1')]

        s = Omega::Client::SolarSystem.new
        s.entity = sys

        @n.should_receive(:invoke).with('cosmos::get_resources', 'ast1').and_return(:res)
        s.asteroids.should == sys.asteroids
        sys.asteroids.first.resources.should == :res
      end
    end

    describe "#entities" do
      it "retrieves entities in system" do
        e = Cosmos::Entities::SolarSystem.new
        s = Omega::Client::SolarSystem.new
        s.entity = e
        @n.should_receive(:invoke).with('manufactured::get_entities', 'under', s.id).
                                   and_return([:ent])
        s.entities.should == [:ent]
      end
    end

    describe "#with_fewest" do
      context "entity_type == station" do
        it 'returns systems sorted by number of user_owned stations in them' do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          s1 = create(:valid_station, :user_id => @login_user.id, :solar_system => sys1)

          sys = Omega::Client::SolarSystem.with_fewest :type => "Manufactured::Station",
                                                       :owned_by => @login_user.id
          sys.should_not be_nil
          sys.id.should == sys1.id
        end
      end
    end

    describe "#closest_neighbor_with_no" do
      context "entity_type == station" do
        it "returns closest system with no user owned station" do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          sys3 = create(:solar_system)
          create(:jump_gate, :solar_system => sys1, :endpoint => sys2)
          create(:jump_gate, :solar_system => sys1, :endpoint => sys3)
          s1 = create(:valid_station, :solar_system => sys2, :user_id => @login_user.id)

          c = Omega::Client::SolarSystem.get(sys1.id)
          n = c.closest_neighbor_with_no :type => "Manufactured::Station",
                                         :owned_by => @login_user.id
          n.id.should == sys3.id
        end
      end

      context "no matching systems" do
        it "returns nil" do
          sys1 = create(:solar_system)
          sys2 = create(:solar_system)
          create(:jump_gate, :solar_system => sys1, :endpoint => sys2)
          s1 = create(:valid_station, :solar_system => sys2, :user_id => @login_user.id)

          c = Omega::Client::SolarSystem.get(sys1.id)
          n = c.closest_neighbor_with_no :type => "Manufactured::Station",
                                         :owned_by => @login_user.id
          n.should be_nil
        end
      end
    end
  end # describe SolarSystem
end # module Omega::Client
