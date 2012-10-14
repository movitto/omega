# Helper module to define omega clients / robots
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/base'
require 'omega/client/user'

module Omega
  module Client
    module DSL
      def gen_uuid
        Motel.gen_uuid
      end

      def rand_resource
        Omega::Resources.rand_resource
      end

      def login(node, username, password)
        Omega::Client::User.login(node, username, password)
      end

      def user(username, password, &bl)
        @user = Users::User.new :id => username, :password => password
        Omega::Client::Tracker.invoke_request('users::create_entity', @user)
        bl.call @user
        @user
      end

      def role(nrole)
        if @user
          Omega::Client::Tracker.invoke_request('users::add_role', @user.id, nrole)

        else
          Omega::Client::Tracker.invoke_request('users::create_entity', nrole)
        end
      end

      def alliance(id, args = {}, &bl)
        alliance = Users::Alliance.new(args.merge({:id => id}))
        Omega::Client::Tracker.invoke_request 'users::create_entity', alliance
        alliance
      end

      def galaxy(name, &bl)
        @galaxy = Cosmos::Galaxy.new :name => name
        Omega::Client::Tracker.invoke_request 'cosmos::create_entity', @galaxy, :universe
        bl.call @galaxy
        @galaxy
      end

      def system(id, star_id = nil, args = {}, &bl)
        begin
          return Omega::Client::SolarSystem.get(id)
        rescue Exception => e
        end

        raise ArgumentError, "galaxy must not be nil" if @galaxy.nil?
        @system = Cosmos::SolarSystem.new(args.merge({:name => id, :galaxy => @galaxy}))
        star = Cosmos::Star.new :name => star_id, :solar_system => @system
        Omega::Client::Tracker.invoke_request 'cosmos::create_entity', @system, @galaxy.name
        unless star_id.nil?
          Omega::Client::Tracker.invoke_request 'cosmos::create_entity', star, @system.name
        end
        bl.call @system
        @system
      end

      def asteroid(id, args={}, &bl)
        raise ArgumentError, "system must not be nil" if @system.nil?
        @asteroid = Cosmos::Asteroid.new(args.merge({:name => id, :solar_system => @system}))
        Omega::Client::Tracker.invoke_request 'cosmos::create_entity', @asteroid, @system.name
        bl.call @asteroid
        @asteroid
      end

      def resource(args = {})
        raise ArgumentError, "asteroid must not be nil" if @asteroid.nil?
        resource = Cosmos::Resource.new(args)
        Omega::Client::Tracker.invoke_request 'cosmos::set_resource', @asteroid.name, resource, args[:quantity]
        resource
      end

      def planet(id, args={}, &bl)
        raise ArgumentError, "system must not be nil" if @system.nil?
        @planet = Cosmos::Planet.new(args.merge({:name => id, :solar_system => @system}))
        Omega::Client::Tracker.invoke_request 'cosmos::create_entity', @planet, @system.name
        bl.call @planet
        @planet
      end

      def moon(id, args={})
        raise ArgumentError, "planet must not be nil" if @planet.nil?
        moon = Cosmos::Moon.new(args.merge({:name => id, :planet => @planet}))
        Omega::Client::Tracker.invoke_request 'cosmos::create_entity', moon, @moon.name
        moon
      end

      def jump_gate(system, endpoint, args = {})
        gate = Cosmos::JumpGate.new(args.merge({:solar_system => system, :endpoint => endpoint}))
        Omega::Client::Tracker.invoke_request 'cosmos::create_entity', gate, system.name
        gate
      end

      def station(id, args={}, &bl)
        st = Manufactured::Station.new(args.merge({:id => id}))
        bl.call st unless bl.nil?
        Omega::Client::Tracker.invoke_request 'manufactured::create_entity', st
        st
      end

      def ship(id, args={}, &bl)
        sh = Manufactured::Ship.new(args.merge({:id => id}))
        bl.call sh unless bl.nil?
        Omega::Client::Tracker.invoke_request 'manufactured::create_entity', sh
        sh
      end
    end
  end
end
