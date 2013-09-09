#!/usr/bin/ruby
# Helper utility to run missions
#
# Run this script with the path to a mission setup script, for example:
#   RUBYLIB='lib' ./bin/util/mission-runner.rb ./examples/story.rb
#
# The missions defined in story.rb will be created on the server side
# before being evaluated here. This script will run through and execute
# each mission, from satisfying reqs, to assigning it, to completing
# it/failing it, each stage is verified and results are reported.
#
# *Note* this requires 'admin' mode to be enabled in the omega-server
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO make sure this stays in sync w/ the missions & omega dsls

require 'colored'
require 'omega/client/dsl'

STORY_SCRIPT = ARGV.shift
$missions = []

#######################################
# override Omega DSL mission method
# - store missions locally
# - dispatch to original behaviour to create missions server side
# - create two missions for every invocation, one which will quickly
#   timeout/fail and one which we run through
module Omega::Client::DSL
  alias :old_mission :mission
  def mission(id, args={})
    sid = id + '-success'
    fid = id + '-failed'
    sargs = args
    fargs = args.merge({:timeout => 1}) # quick expiration
    $missions << [sid, :success, sargs]
    $missions << [fid, :failed,  fargs] 
    old_mission(sid, sargs)
    old_mission(fid, fargs)
  end
end

#######################################
# require story script user specified
ARGV = ['Athena'] # XXX remove me
$: << File.dirname(STORY_SCRIPT)
require File.basename(STORY_SCRIPT, ".rb")
athena = system('Athena') # XXX remove me

#######################################
# setup user to run through missions
test_user = user 'test-user', 'test-user'
$user_id = test_user.id

# create a ship
test_ship = ship(gen_uuid, :user_id => test_user.id,
                 :system_id => athena.id, :location => rand_location,
                 :type => :corvette)

#######################################
# Helper methods

# return # of missions succeeded / failed
def mission_attrs_for(user_id)
  current_user = invoke('users::get_entity', 'with_id', user_id)
  attr = current_user.attributes.find { |a|
    a.type == Users::Attributes::MissionsCompleted.id }
  successes = attr.nil? ? 0 : attr.total
  attr = current_user.attributes.find { |a|
      a.type == Users::Attributes::MissionsFailed.id }
  failures = attr.nil? ? 0 : attr.total
  [successes,failures]
end

#######################################
# process each local mission
$missions.each { |id, scenario, args|
  # retrieve server mission
  smission = invoke('missions::get_mission', 'with_id', id)
  puts "processing mission #{smission.id}".yellow

  #######################################
  # run through requirements, setting up scenario where they are satisfied
  args[:requirements] = [args[:requirements]].flatten
  args[:requirements].each { |req|
    puts "satisfying req #{req.dsl_method}".yellow
    case req.dsl_method
    when "shared_station" then
      # create user ship docked at first creator station w/ ship
      station = invoke('manufactured::get_entities',
                        'of_type', 'Manufactured::Ship',
                        'owned_by', smission.creator_id).
                  collect { |sh| sh.docked_at }.compact.first
      sh = Manufactured::Ship.new :id => gen_uuid,
                                  :user_id => $user_id,
                                  :system_id => station.system_id,
                                  :docked_at => station,
                                  :location  => station.location + [10,10,10],
                                  :type => :corvette
      invoke('manufactured::create_entity', sh)
    when "docked_at" then
      # create user ship docked at specified station
      station = req.params.first
      sh = Manufactured::Ship.new :id => gen_uuid,
                                  :system_id => station.system_id,
                                  :docked_at => station
      invoke('manufactured::create_entity', sh)
    end
  }

  #######################################
  # assign mission
  puts "Assigning mission #{id}".yellow
  invoke('missions::assign_mission', id, $user_id)

  # refresh server mission
  smission = invoke('missions::get_mission', 'with_id', id)

  # validate results of assignment callbacks
# FIXME raise errs / output if checks fail
  args[:assignment_callbacks].each { |cb|
    print "validating assignment callback #{cb.dsl_method} ".yellow

    case cb.dsl_method
    when 'store' then
      # lookup data stored in mission
      # TODO resolve and invoke lookup to set value
      result = smission.mission_data[cb.params.first].nil?
      print result ? "failed".red : "succeeded".green

    when 'create_entity' then
      # lookup entity created
      entity_id = smission.mission_data[cb.params.first].id
      entity = invoke('manufactured::get_entity', 'with_id', entity_id)
      result = entity.nil?
      print result ? "failed".red : "succeeded".green

    when 'create_asteroid' then
      # lookup asteroid created
      ast_id = smission.mission_data[cb.params.first].id
      ast = invoke('cosmos::get_entity', 'with_id', ast_id)
      result = ast.nil?
      print result ? "failed".red : "succeeded".green

    when 'create_resource' then
      # lookup asteroid resource was set on, ensure it has resource
      ast_id = smission.mission_data[cb.params.first].id
      ast = invoke('cosmos::get_entity', 'with_id', ast_id)
      res = ast.resources.find { |r|
              r.material_id == cb.params[1][:material_id]
              r.quantity    >= cb.params[1][:quantity]
            }
      result = res.nil?
      print result ? "failed".red : "succeeded".green

    when 'add_resource' then
      # lookup entity resource was set on, ensure it has resource
      entity_id = smission.mission_data[cb.params.first].id
      entity = invoke('manufactured::get_entity', 'with_id', entity_id)
      res = entity.resources.find { |r|
              r.material_id == cb.params[1][:material_id]
              r.quantity    >= cb.params[1][:quantity]
            }
      result = res.nil?
      print result ? "failed".red : "succeeded".green

    when 'subscribe_to' then
      # TODO ensure missions registry has event handler for specified
      #      manufactured event and ensure missions rjr node is subscribe
      #      to manufactured event callback

    when 'schedule_expiration_event' then
      # TODO ensure missions registry has mission expiration event
    end

    puts ""
  }

  # grab some data before completing the mission
  successes, failures = mission_attrs_for $user_id

  #######################################
  # launch one of the two success / failed scenarios
  if scenario == :success
    # run through victory conditions, manually triggering them
    # TODO XXX the missions system doesn't necessarily take these into
    # account when processing missions, see the checks in the Event
    # namespace in the Missions::DSL. This needs to be resolved, but
    # for now we'll do some manual work to set victory to true
    args[:victory_conditions] = [args[:victory_conditions]].flatten
    args[:victory_conditions].each { |cond|
      puts "resolving victory condition #{cond.dsl_method}".yellow

      case cond.dsl_method
      when 'check_entity_hp' then
        entity_id = smission.mission_data[cond.params.first].id
        entity = invoke('manufactured::get_entity', 'with_id', entity_id)
        entity.hp = 0
        invoke('manufactured::admin::set', entity)
        invoke('manufactured::admin::run_callbacks', entity_id,
               'destroyed_by', test_ship)

      when 'check_mining_quantity' then
        # set tracked mission resource quantity to
        # target mission resource quantity
        smission.mission_data[:quantity] =
          smission.mission_data[:resources][mission.mission_data[:target]]

        # trigger resource collected callback
        res = Cosmos::Resource.new :material_id => smission.mission_data[:target],
                                   :quantity    => smission.mission_data[:quantity]
        invoke('manufactured::admin::run_callbacks', test_ship.id,
               'resource_collected', test_ship, res)

      when 'check_transfer' then
        # set tracked mission transfer entity to target
        # mission transfer entity
        ct  = smission.mission_data[:check_transfer]
        res = Cosmos::Resource.new(:material_id => ct[:rs].material_id,
                                   :quantity    => ct[:rs].quantity)
        smission.mission_data[:last_transfer] =
          { :dst => ct[:dst], :rs  => res }

        # trigger transferred_to callback
        invoke('manufactured::admin::run_callbacks', test_ship.id,
               'transferred_to', test_ship, ct[:dst], res)

      when 'collected_loot' then
        # set tracked mission loot to target
        # mission loot
        cl = smission.mission_data[:check_loot]
        res =Cosmos::Resource.new(:material_id => cl.material_id,
                                  :quantity    => cl.quantity) 
        smission.mission_data[:loot] = [res]

        # trigger collected_loot callback
        invoke('manufactured::admin::run_callbacks', test_ship.id,
               'collected_loot', test_ship, res)

      end
    }

    # sleep for a few event poll delays
    sleep(Omega::Server::Registry::DEFAULT_EVENT_POLL * 3)

    # validate callbacks results
    args[:victory_callbacks].each { |cb|
      print "validating victory callback #{cb.dsl_method} ".yellow

      case cb.dsl_method
      when 'add_reward' then
        # ensure resource has been added to the first user ship
        entity = invoke('manufactured::get_entities', 'owned_by', $user_id).first
        rs = entity.resources.find { |rs|
               rs.material_id == cb.params.first.material_id &&
               rs.quantity >= cb.params.first.quantity
             }
        result = rs.nil?
        print result ? "failed".red : "succeeded".green

      when 'update_user_attributes' then
        # ensure user has updated attribute
        nsuccesses, nfailures = mission_attrs_for $user_id
        result = nsuccesses == successes + 1 &&
                 nfailures  == failures
        print !result ? "failed".red : "succeeded".green

      when 'cleanup_events' then
        # TODO ensure event handlers and expiration event are removed

      when 'recycle_mission' then
        # TODO ensure mission is cloned / new mission added
      end

      puts ""
    }

  else
    # sleep for a few event poll delays
    sleep(Omega::Server::Registry::DEFAULT_EVENT_POLL * 2)

    # TODO sleep if 1s timeout hasn't yet transpired
    args[:failure_callbacks].each { |cb|
      print "validating failure callback #{cb.dsl_method} ".yellow

      case cb.dsl_method
      #when 'add_reward' then
      when 'update_user_attributes' then
        # ensure user has updated attribute
        nsuccesses, nfailures = mission_attrs_for $user_id
        result = nsuccesses == successes &&
                 nfailures  == failures + 1
        print !result ? "failed".red : "succeeded".green

      when 'cleanup_events' then
        # TODO
      when 'recycle_mission' then
        # TODO
      end

      puts ""
    }
  end

  puts ""
}
#######################################
