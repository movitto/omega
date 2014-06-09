# Motel Tracker RJR callback helper
#
# Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

require 'motel/callbacks/movement'
require 'motel/callbacks/stopped'
require 'motel/callbacks/rotation'
require 'motel/callbacks/proximity'
require 'motel/callbacks/changed_strategy'

module Motel::RJR
  # Helper to generate a new callback from the specified method & args.
  # Will validate arguments in the context of their method
  def callback_for(rjr_method, args)
    case rjr_method
    when "motel::track_movement"
      d = args.shift
      raise ArgumentError, "distance must be >0" unless d.numeric? && d.to_f > 0
      Callbacks::Movement.new(:min_distance => d.to_f,
                              :rjr_event    => 'motel::on_movement',
                              :event_type   => :movement)

    when 'motel::track_rotation'
      rt = args.shift
      raise ArgumentError,
        "#{rt} must >0 && <4*PI" unless rt.numeric? &&
                                        rt.to_f > 0 &&
                                        (0...4*Math::PI).include?(rt.to_f)

      ax = args.shift
      ay = args.shift
      az = args.shift
      raise ArgumentError,
        "rotation axis must be normalized" unless ax.nil? || ay.nil? || az.nil? ||
                                                  Motel.normalized?(ax, ay, az)

      Callbacks::Rotation.new :rot_theta    => rt.to_f,
                              :axis_x       => ax,
                              :axis_y       => ay,
                              :axis_z       => az,
                              :rjr_event    => 'motel::on_rotation',
                              :event_type   => :rotation

    when 'motel::track_proximity'
      olid = args.shift
      oloc = registry.entity &with_id(olid)
      raise Omega::DataNotFound, "loc specified by #{olid} not found" if oloc.nil?

      pevent  = args.shift
      vevents = ['proximity', 'entered_proximity', 'left_proximity']
      raise ArgumentError,
        "event must be one of #{vevents.join(", ")}" unless vevents.include?(pevent)

      d = args.shift
      raise ArgumentError,
        "dist must be >0" unless d.numeric? && d.to_f > 0

      Callbacks::Proximity.new :max_distance => d.to_f,
                               :to_location  => oloc,
                               :rjr_event    => 'motel::on_proximity',
                               :event_type   => :proximity

    when 'motel::track_stops'
      Callbacks::Stopped.new :rjr_event   => 'motel::location_stopped',
                             :event_type  => :stopped

    when 'motel::track_strategy'
      Callbacks::ChangedStrategy.new :rjr_event  => 'motel::changed_strategy',
                                     :event_type => :changed_strategy

    end
  end
end # module Motel::RJR
