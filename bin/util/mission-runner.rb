#!/usr/bin/ruby
# Helper utility to run missions
#
# Run this script with the path to a mission setup script, for example:
#   RUBYLIB='lib' ./bin/util/mission-runner.rb ./examples/story.rb <args_to_story.rb>
#
# The missions defined in story.rb will be created on the server side
# before being evaluated here. This script will run through and execute
# each mission, from satisfying reqs, to assigning it, to completing
# it/failing it, each stage is verified and results are reported.
#
# *Note* this requires 'admin' mode to be enabled in the omega-server.
# Also if user attributes are disabled, related checks will fail (see TODO below)
#
# Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO make sure this stays in sync w/ the missions & omega dsls

require 'colored'
require 'omega/client/dsl'
require 'users/attributes/stats'

STORY_SCRIPT = ARGV.shift
STORY_ARGS   = ARGV
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
$: << File.dirname(STORY_SCRIPT)
require File.basename(STORY_SCRIPT, ".rb")

# XXX for time being just assume first are is system
# we're primarily operating in
athena = system(ARGV.first)

#######################################
# setup user to run through missions
test_user = user 'test-user', 'test-user'
$user_id = test_user.id

# create a couple ships
test_corvette =
  ship(gen_uuid, :user_id => test_user.id,
       :system_id => athena.id, :location => rand_location,
        :type => :corvette, :cargo_capacity => 5000)

test_miner =
  ship(gen_uuid, :user_id => test_user.id,
       :system_id => athena.id, :location => rand_location,
       :type => :mining, :cargo_capacity => 5000)

#######################################
# Helper methods

# return # of missions succeeded / failed
def mission_attrs_for(user_id)
  current_user = invoke('users::get_entity', 'with_id', user_id)
  attr = current_user.attributes.find { |a|
    a.type.id == Users::Attributes::MissionsCompleted.id }
  successes = attr.nil? ? 0 : attr.level
  attr = current_user.attributes.find { |a|
      a.type.id == Users::Attributes::MissionsFailed.id }
  failures = attr.nil? ? 0 : attr.level
  [successes,failures]
end

#######################################
# process each local mission
$missions.each { |id, scenario, args|
  # retrieve server mission
  smission = invoke('missions::get_mission', 'with_id', id)
  puts "processing mission #{smission.title}".yellow

  #######################################
  # run through requirements, setting up scenario where they are satisfied
  args[:requirements] = [args[:requirements]].flatten.compact
  args[:requirements].each { |req|
    puts "satisfying req #{req.dsl_method}".yellow
    case req.dsl_method
    when "shared_station" then
      # create user ship docked at first creator station w/ ship
      station = invoke('manufactured::get_entities',
                        'of_type', 'Manufactured::Ship',
                        'owned_by', smission.creator_id).
                  collect { |sh| sh.docked_at }.compact.first
      test_miner.dock_at station
      invoke('manufactured::admin::set', test_miner)
    when "docked_at" then
      # create user ship docked at specified station
      station = req.params.first
      test_miner.dock_at station
      invoke('manufactured::admin::set', test_miner)
    end
  }

  #######################################
  # assign mission
  puts "Assigning mission #{smission.title}".yellow
  invoke('missions::assign_mission', id, $user_id)

  # refresh server mission
  smission = invoke('missions::get_mission', 'with_id', id)

  # validate results of assignment callbacks
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
      print "skipping".blue

    when 'schedule_expiration_event' then
      # TODO ensure missions registry has mission expiration event
      print "skipping".blue
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
               'destroyed_by', test_corvette)

      when 'check_mining_quantity' then
        # trigger resource collected callback
        m = smission.mission_data['target']
        q = smission.mission_data['quantity']
        res = Cosmos::Resource.new(:material_id => m, :quantity => q)
        invoke('manufactured::admin::run_callbacks', test_miner.id,
               'resource_collected', res, q)

      when 'check_transfer' then
        # trigger transferred_to callback
        ct  = smission.mission_data['check_transfer']
        res = Cosmos::Resource.new(:material_id => ct['rs'],
                                   :quantity    => ct['q'])
        invoke('manufactured::admin::run_callbacks', test_miner.id,
               'transferred_to', ct['dst'], res)

      when 'collected_loot' then
        # set tracked mission loot to target
        # mission loot
        cl = smission.mission_data['check_loot']
        res =Cosmos::Resource.new(:material_id => cl['res'],
                                  :quantity    => cl['q']) 

        # trigger collected_loot callback
        invoke('manufactured::admin::run_callbacks', test_corvette.id,
               'collected_loot', res)

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
        # TODO skip is user attributes disabled
        # ensure user has updated attribute
        nsuccesses, nfailures = mission_attrs_for $user_id
        result = nsuccesses == successes + 1 &&
                 nfailures  == failures
        print !result ? "failed".red : "succeeded".green

      when 'cleanup_events' then
        # TODO ensure event handlers and expiration event are removed
        print "skipping".blue

      when 'recycle_mission' then
        # TODO ensure mission is cloned / new mission added
        print "skipping".blue
      end

      puts ""
    }

  else
    # sleep for a few event poll delays
    sleep(Omega::Server::Registry::DEFAULT_EVENT_POLL * 2)

    args[:failure_callbacks].each { |cb|
      print "validating failure callback #{cb.dsl_method} ".yellow

      case cb.dsl_method
      #when 'add_reward' then
      when 'update_user_attributes' then
        # TODO skip is user attributes disabled
        # ensure user has updated attribute
        nsuccesses, nfailures = mission_attrs_for $user_id
        result = nsuccesses == successes &&
                 nfailures  == failures + 1
        print !result ? "failed".red : "succeeded".green

      when 'cleanup_events' then
        # TODO
        print "skipping".blue
      when 'recycle_mission' then
        # TODO
        print "skipping".blue
      end

      puts ""
    }
  end

  puts ""
}
#######################################
