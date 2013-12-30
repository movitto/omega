#!/usr/bin/ruby
# Helper utility to take & verify an omega backup
#
# This script should be run w/out arguments like so:
#   RUBYLIB='lib' ./bin/util/verify-backup.rb

require 'tempfile'

require 'omega'
require 'rjr/nodes/tcp'

### config
USER     = 'admin'
PASSWORD = 'nimda'
URL      = 'jsonrpc://localhost:8181'
SERVER   = 'bin/omega-server'

TO_VERIFY = {
  :classes =>
    {Omega::Server::Event => :event,
     Users::User => :user,
     Users::Role => :role,
     Users::Events::RegisteredUser => :user_events,
     Users::Attribute => :attribute,
     Users::Privilege => :privilege,
     Motel::Location => :location,
     Motel::MovementStrategy => :movement_strategy,
     Motel::MovementStrategies::Linear => :linear,
     Motel::MovementStrategies::Rotatable => :rotate,
     Motel::MovementStrategies::Elliptical => :elliptical,
     Motel::MovementStrategies::Follow => :follow,
     Cosmos::Resource => :resource,
     Manufactured::Ship => :ship,
     Manufactured::Station => :station,
     Manufactured::Loot => :loot,
     Missions::Mission => :mission,
     Missions::Events::Manufactured => :missions_event_manu,
     Missions::Events::User => :missions_event_user,
     Missions::Events::PopulateResource => :missions_event_resource}

  :event => [:id, :timestamp],

  :user =>
    [:id, :email, :roles, :password, :secure_password,
     :registration_code, :created_at, :last_modified_at,
     :last_login_at, :permenant, :npc, :attributes], # FIXME recaptcha also needed

  :role => [:id, :privileges],
    
  :attribute => [:type, :level, :progression, :user],
    
  :user_events => [:user]

  :location =>
    [:id, :parent_id, :x, :y, :z, :parent, :children,
     :orientation_x, :orientation_y, :orientation_z,
     :movement_strategy, :next_movement_strategy,
     :restrict_view, :restrict_modify, :last_moved_at],

  :movement_strategy => [:step_delay],
    
  :linear => [:dx, :dy, :dz, :speed],

  :rotate => [:rot_x, :rot_y, :rot_z, :rot_theta],

  :elliptical =>
    [:relative_to, :speed, :e, :p,
     :dmajx, :dmajy, :dmajz, :dminx, :dminy, :dminz],

  :follow =>
    [:tracked_location_id, :tracked_location, :distance, :speed],

  :resource =>
    [:id, :material_id, :entity_id, :entity, :quantity],

  :ship =>
    [:id, :user_id, :size, :distance_moved, :type, :movement_speed,
     :rotation_speed, :attack_distance, :attack_rate, :damage_dealt,
     :hp, :max_shield_level, :shield_level, :shield_refresh_rate,
     :destroyed_by, :mining_rate, :mining_quantity, :mining_distance,
     :docked_at, :docked_at_id, :attacking, :mining,
     :collection_distance, :location, :solar_system, :system_id,
     :resources, :cargo_capacity, :transfer_distance],

  :station =>
    [:id, :user_id, :size, :type, :docking_distance,
     :construction_distance, :location, :solar_system,
     :system_id, :resources, :cargo_capacity, :transfer_distance],

  :loot =>
    [:id, :location, :solar_system, :system_id, :resources,
     :cargo_capacity, :transfer_distance],

  :mission =>
    [:id, :title, :description, :mission_data, :creator_id,
     :assigned_to_id, :assigned_to, :assigned_time,
     :timeout, :victorious, :failed], # FIXME callbacks also needed

  :missions_events_manu =>
    [:manufactured_event_args],

  :missions_events_user =>
    [:users_event_args],

  :missions_events_resource =>
    [:resource, :from_resources, :entity, :from_entities, :quantity]
}

### helpers

class AssertionError < RuntimeError ; end
def assert(&bl)
  raise AssertionError unless yield
end

def verify(orig,current)
  # TODO skip if already verified (how to determine?)
  attrs = TO_VERIFY[TO_VERIFY[:classes][orig.class]]
  attrs.each do |a|
    oval = orig.send(a)
    cval = current.send(a)

    if TO_VERIFY[:classes].keys.any? { |cl| oval.kind_of?(cl) }
      verify oval, cval
    else
      assert { oval == cval }
    end
  end
end

def node
  @node ||= RJR::Nodes::TCP.new :node_id => 'omega-verify-backup'
end

def url
  URL
end

def login
  admin   = Users::User.new(:id => USER, :password => PASSWORD)
  session = node.invoke(url, 'users::login', admin)
  node.message_headers['session_id'] = session.id
end

def status
  {:users    => node.invoke(url, 'users::status'),
   :motel    => node.invoke(url, 'motel::status'),
   :manu     => node.invoke(url, 'manufactured::status'),
   :missions => node.invoke(url, 'missions::status')}
end

def entities
  { :users =>
      {:users => node.invoke(url, 'users::get_entities', 'of_type', 'Users::User')
       :roles => node.invoke(url, 'users::get_entities', 'of_type', 'Users::Role')}
    :motel =>
      {:locations => node.invoke(url, 'motel::get_location')}
    :manu =>
      {:ships    => node.invoke(url, 'manufactured::get_entities',
                              'of_type', 'Manufactured::Ship' ),
       :stations => node.invoke(url, 'manufactured::get_entities',
                              'of_type', 'Manufactured::Station')}
    :missions =>
      {:missions => node.invoke(url, 'missions::get_missions')} }
end

def backup_file
  @backup_file ||= Tempfile.new
end

def backup_server
  node.invoke(url, 'users::save_state',        backup_file.path)
  node.invoke(url, 'motel::save_state',        backup_file.path)
  node.invoke(url, 'cosmos::save_state',       backup_file.path)
  node.invoke(url, 'manufactured::save_state', backup_file.path)
  node.invoke(url, 'missions::save_state',     backup_file.path)
  backup_file
end

def restore_server
  node.invoke('users::restore_state',        backup_file.path)
  node.invoke('motel::restore_state',        backup_file.path)
  node.invoke('cosmos::restore_state',       backup_file.path)
  node.invoke('manufactured::restore_state', backup_file.path)
  node.invoke('missions::restore_state',     backup_file.path)
end

def restart_server
  # TODO
end

def verify_users(results)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify user status and entities
  assert { ostatus[:users][:users] == cstatus[:users][:users] }
  0.upto(oentities[:users][:users].size) do |u|
    ouser = oentities[:users][:users][u]
    nuser = centities[:users][:users][u]
    verify ouser, nuser
  end
  
  # verify role status and entities
  assert { ostatus[:users][:roles] == cstatus[:users][:roles] }
  0.upto(oentities[:users][:roles].size) do |r|
    orole = oentities[:users][:roles][r]
    nrole = centities[:users][:roles][r]
    verify orole, nrole
  end
  
  # TODO need to retrieve / verify events
end

def verify_motel(results)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify location status and entities
  assert { ostatus[:motel][:num_locations] == cstatus[:motel][:num_locations] }
  0.upto(oentities[:motel][:locations].length).each do |i|
    oloc = oentities[:motel][:locations][i]
    cloc = centities[:motel][:locations][i]
    verify oloc, cloc
  end
end

def verify_cosmos(results)
  # TODO cosmos entities & resources
end

def verify_manu(results)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify ship status and entities
  assert { ostatus[:manu][:ships] == cstatus[:manu][:ships] }
  0.upto(oentities[:manu][:ships].length).each do |i|
    oship = oentities[:manu][:ships][i]
    cship = centities[:manu][:ships][i]
    verify oship, cship
  end

  # verify station status and entities
  assert { ostatus[:manu][:stations] == cstatus[:manu][:stations] }
  0.upto(oentities[:manu][:stations].length).each do |i|
    ostation = oentities[:manu][:stations][i]
    cstation = centities[:manu][:stations][i]
    verify ostation, cstation
  end

  # verify no commands
  assert { status[:manu][:commands].length == 0 }

  # TODO need to verify loot
end

def verify_missions(results)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify mission status and entities
  assert { ostatus[:missions][:missions] == cstatus[:missions][:missions] }
  0.upto(oentities[:missions][:missions].length).each do |i|
    omission = oentities[:missions][:missions][i]
    cmission = centities[:missions][:missions][i]
    verify omission, cmission

  # TODO need to verify events
end

def verify_all(results)
  verify_users    results
  verify_motel    results
  verify_cosmos   results
  verify_manu     results
  verify_missions results
end

### main
login
orig_status  = status
orig_entites = entities
backup_server
restart_server
login
restore_server
current_status   = status
current_entities = entities
verify_all :orig     => {:status => orig_status,    :entities => orig_entities},
           :current  => {:status => current_status, :entities => current_entities}
