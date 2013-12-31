#!/usr/bin/ruby
# Helper utility to take & verify an omega backup
#
# Relies on the omega inspection interface (see bin/omega-server
# for how to enable)
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
SERVER   = 'bin\/omega-server'
SERVER_LOG = 'backup-server.log'

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
     Missions::Events::Users => :missions_event_user,
     Missions::Events::PopulateResource => :missions_event_resource},

  :event => [:id, :timestamp],

  :user =>
    [:id, :email, :roles, :password, :secure_password,
     :registration_code, :created_at, :last_modified_at,
     :last_login_at, :permenant, :npc, :attributes], # FIXME recaptcha also needed

  :role => [:id, :privileges],
    
  :attribute => [:type, :level, :progression], # FIXME should also verify user but results in circular reference

  :privilege => [:id, :entity_id],
    
  :user_events => [:user],

  :location =>
    [:id, :parent_id, :parent, :children,
     # FIXME should verify but may have moved:
     #:x, :y, :z, :orientation_x, :orientation_y, :orientation_z, :last_moved_at,
     :movement_strategy, :next_movement_strategy,
     :restrict_view, :restrict_modify],

  :movement_strategy => [:step_delay],
    
  :linear => [:dx, :dy, :dz, :speed],

  :rotate => [:rot_x, :rot_y, :rot_z, :rot_theta],

  :elliptical =>
    [:relative_to, :speed, :e, :p,
     :dmajx, :dmajy, :dmajz, :dminx, :dminy, :dminz],

  :follow =>
    [:tracked_location_id, :tracked_location, :distance, :speed],

  :resource =>
    [:id, :material_id, :entity_id, :quantity], # FIXME should also test entity but results in circular reference

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

def node
  @node ||= RJR::Nodes::TCP.new :node_id => 'omega-verify-backup'
end

def reset_node
  @node = nil
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
      {:users => node.invoke(url, 'users::get_entities', 'of_type', 'Users::User'),
       :roles => node.invoke(url, 'users::get_entities', 'of_type', 'Users::Role')},
    :motel =>
      {:locations => node.invoke(url, 'motel::get_location')},
    :cosmos =>
      {:asteroids     => node.invoke(url, 'cosmos::get_entities',
                        'of_type', 'Cosmos::Entities::Asteroid'),
       :galaxies      => node.invoke(url, 'cosmos::get_entities',
                          'of_type', 'Comsos::Entities::Galaxy'),
       :jump_gates    => node.invoke(url, 'cosmos::get_entities',
                          'of_type', 'Comsos::Entities::Galaxy'),
       :moons         => node.invoke(url, 'cosmos::get_entities',
                          'of_type', 'Comsos::Entities::Galaxy'),
       :planets       => node.invoke(url, 'cosmos::get_entities',
                          'of_type', 'Comsos::Entities::Galaxy'),
       :solar_systems => node.invoke(url, 'cosmos::get_entities',
                          'of_type', 'Comsos::Entities::Galaxy'),
       :stars         => node.invoke(url, 'cosmos::get_entities',
                          'of_type', 'Comsos::Entities::Galaxy')},
    :manu =>
      {:ships    => node.invoke(url, 'manufactured::get_entities',
                              'of_type', 'Manufactured::Ship' ),
       :stations => node.invoke(url, 'manufactured::get_entities',
                              'of_type', 'Manufactured::Station')},
    :missions =>
      {:missions => node.invoke(url, 'missions::get_missions')} }
end

def backup_file
  @backup_file ||= Tempfile.new('omega-verify-backup')
end

def pid
  pid = nil
  Dir['/proc/[0-9]*/cmdline'].each do |p|
    if File.read(p) =~ /.*#{SERVER}.*/
      pid = p.split('/')[2].to_i
      break
    end
  end
  pid
end

def backup_server
  Process.kill "USR1", pid
  sleep 20
end

def restore_server
  Process.kill "USR2", pid
  sleep 20
end

def kill_server
  raise "server process not found" if pid.nil?
  Process.kill "TERM", pid
end

def restart_server
  kill_server
  reset_node
  sleep 2 # old server cool down time
  fork do
    `#{SERVER} >& #{SERVER_LOG}`
  end
  sleep 2 # new server start up time
end

class AssertionError < RuntimeError ; end
def assert(message='', &bl)
  raise AssertionError, message unless yield
end

def verify(msg, orig, current)
# TODO skip if orig already verified (how to determine?)
  TO_VERIFY[:classes].keys.each do |cl|
    next unless orig.kind_of?(cl)
    attrs = TO_VERIFY[TO_VERIFY[:classes][cl]]
    attrs.each do |a|
      oval = orig.send(a)
      cval = current.send(a)

      if oval.is_a?(Array)
        # assuming attribute array isn't multidimensional
        0.upto(oval.size-1) do |i|
          ovali = oval[i]
          cvali = cval[i]

          if TO_VERIFY[:classes].keys.any? { |cl| ovali.kind_of?(cl) }
            verify "#{msg}:#{a}[#{i}]", ovali, cvali
          else
            assert("#{msg}:#{ovali.to_s} != #{cvali.to_s}") { ovali == cvali }
          end
        end

      elsif TO_VERIFY[:classes].keys.any? { |cl| oval.kind_of?(cl) }
        verify "#{msg}:#{a}", oval, cval
      else
        assert("#{msg}:#{oval.to_s} != #{cval.to_s}") { oval == cval }
      end
    end
  end
end

def verify_users(result)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify user status and entities
  assert { ostatus[:users]['users'] == cstatus[:users]['users'] }
  0.upto(oentities[:users][:users].size-1) do |u|
    ouser = oentities[:users][:users][u]
    nuser = centities[:users][:users][u]
    verify "user #{ouser.id}", ouser, nuser
  end
  
  # verify role status and entities
  assert { ostatus[:users]['roles'] == cstatus[:users]['roles'] }
  0.upto(oentities[:users][:roles].size-1) do |r|
    orole = oentities[:users][:roles][r]
    nrole = centities[:users][:roles][r]
    verify "role #{orole.id}", orole, nrole
  end
  
  # TODO need to retrieve / verify events
end

def verify_motel(result)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify location status and entities
  assert { ostatus[:motel]['num_locations'] == cstatus[:motel]['num_locations'] }
  0.upto(oentities[:motel][:locations].size-1).each do |i|
    oloc = oentities[:motel][:locations][i]
    cloc = centities[:motel][:locations][i]
    verify "location #{oloc.id}", oloc, cloc
  end
end

def verify_cosmos(result)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  oentities[:cosmos].each do |cl,entities|
    0.upto(entities.size-1) do |i|
      oentity = oentities[:cosmos][cl][i]
      centity = centities[:cosmos][cl][i]
      verify "#{cl} #{oentity.id}", oentity, centity
    end
  end

  # TODO need to verify resources (& status once it's available)
end

def verify_manu(result)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify ship status and entities
  assert { ostatus[:manu]['ships'] == cstatus[:manu]['ships'] }
  0.upto(oentities[:manu][:ships].size-1).each do |i|
    oship = oentities[:manu][:ships][i]
    cship = centities[:manu][:ships][i]
    verify "ship #{oship.id}", oship, cship
  end

  # verify station status and entities
  assert { ostatus[:manu]['stations'] == cstatus[:manu]['stations'] }
  0.upto(oentities[:manu][:stations].size-1).each do |i|
    ostation = oentities[:manu][:stations][i]
    cstation = centities[:manu][:stations][i]
    verify "station #{ostation.id}", ostation, cstation
  end

  # verify no commands
  assert { cstatus[:manu]['commands'].size == 0 }

  # TODO need to verify loot
end

def verify_missions(result)
  ostatus   = result[:orig][:status]
  cstatus   = result[:current][:status]
  oentities = result[:orig][:entities]
  centities = result[:current][:entities]

  # verify mission status and entities
  assert { ostatus[:missions]['missions'] == cstatus[:missions]['missions'] }
  0.upto(oentities[:missions][:missions].size-1).each do |i|
    omission = oentities[:missions][:missions][i]
    cmission = centities[:missions][:missions][i]
    verify "mission #{omission.id}", omission, cmission
  end

  # TODO need to verify events
end

def verify_all(result)
  verify_users    result
  verify_motel    result
  verify_cosmos   result
  verify_manu     result
  verify_missions result
end

### main
login
orig_status  = status
orig_entities = entities
backup_server

begin
restart_server
login
restore_server
current_status   = status
current_entities = entities
verify_all :orig     => {:status => orig_status,    :entities => orig_entities},
           :current  => {:status => current_status, :entities => current_entities}

nyan = <<EOS
-_-_-_-_-_-_-_,------,
_-_-_-_-_-_-_-|   /\\_/\\
-_-_-_-_-_-_-~|__( ^ .^)
_-_-_-_-_-_-_-""  ""       verified!
EOS
puts nyan

ensure
kill_server
end
