# Towards Movement Strategy integration tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/towards'

module Motel::MovementStrategies
describe Towards, :integration => true do
  let(:towards) { build(:ms_towards)           }
  let(:loc)     { build(:location)             }
  let(:target)  { build(:location).coordinates }

  def assert_arrived!(data)
    towards.arrived?(loc).should be_true, "data: #{data}"
  end

  def distance_str
    "%06.8f" % towards.distance_from_target(loc).round_to(8)
  end

  def rot_str
    ro = "%04.2f" % towards.rot_theta
    rt = towards.rotation_to_target(loc).first.round_to(2)

    ts = towards.speed.round_to(2)
    dt = towards.direction_to_target(loc)
    aa = Motel.axis_angle(*towards.dir, *dt).first.round_to(2)

    towards.rotating?(loc) ? "R: #{ro} A: #{rt}" : "V: #{ts} A: #{aa}"
  end

  def coords_str
    loc.coordinates.collect { |c| c.round_to(8) }.join(', ')
  end

  def orient_str
    loc.orientation.collect { |o| o.round_to(8) }.join(', ')
  end

  def dir_str
    towards.dir.collect { |d| d.round_to(8) }.join(', ')
  end

  def near_str
    d = towards.moving? ? "D:#{distance_str}" : ""
    c = "C #{coords_str}"
    o = "O #{orient_str}"
    "#{rot_str} #{d} #{c} #{o} - #{towards.moving_towards_target?(loc)}"
  end

  def far_str
    d = towards.moving? ? "D:#{distance_str} > #{towards.near_distance.round_to(2)}" : ""
    di = "M: #{dir_str}"
    "#{rot_str} #{d} #{di}"
  end

  def debug_str
    "C:#{towards.change?(loc)}/S:#{"%-4s" % towards.state(loc)} - "\
    "#{towards.state(loc) == 'near' ? near_str : far_str}"
  end

  def run_movement(params)
    # reset
    loc.angle_rotated = loc.distance_moved = 0
    towards.arriving  = false
    towards.speed = 1

    # location and target
    loc.coordinates      = params[:coordinates]
    loc.orientation      = params[:orientation]
    towards.target       = params[:target]

    # movement constraints
    towards.rot_theta    = params[:rot_theta]
    towards.max_speed    = params[:max_speed]
    towards.acceleration = params[:acceleration]

    # initial velocity
    towards.dir          = params[:dir]   if params[:dir]
    towards.speed        = params[:speed] if params[:speed]

    # run movement
    steps  = params[:steps] || 50000
    format = "%0#{steps.digits}d"
    delay  = params[:delay] || 0.01
    output = params[:output]
    0.upto(steps) do |step|
      towards.move loc, delay
      puts "#{format % step.to_s} #{debug_str}" if output
      break if towards.change?(loc)
    end
  end

  it "runs movement" do
    tests = 500
    0.upto(tests) do |test|
      speed        = acceleration = 0
      speed        = (rand * 1000000).to_i until speed        != 0
      acceleration = (rand * 1000000).to_i  until acceleration != 0

      data = { :coordinates  => build(:location).coordinates,
               :orientation  => Motel.rand_vector,
               :target       => build(:location).coordinates,
               :rot_theta    => rand * 2 * Math::PI,
               :max_speed    => speed,
               :acceleration => acceleration }

      run_movement data
      assert_arrived! data
    end
  end

  context "location is far away from target" do
    it "runs movement" do
      data1 = { :coordinates  => [ 0, 1000, 0],
                :orientation  => [-1,    0, 0],
                :target       => [ 0,    0, 0],
                :rot_theta    => Math::PI/4,
                :max_speed    => 100,
                :acceleration => 10 }

      data2 = { :coordinates  => [ 1000, 0, 0],
                :orientation  => [   -1, 0, 0],
                :target       => [    0, 0, 0],
                :rot_theta    => Math::PI/4,
                :max_speed    => 100,
                :acceleration => 10 }

      run_movement    data1
      assert_arrived! data1

      run_movement    data2
      assert_arrived! data2
    end
  end

  context "location is near target"

  context "not enough time to orchestrate manuver"

  context "high max_speed to acceleration ratio" do
    it "runs movement" do
      movement = [{:max_speed    => 10000000000,
                   :acceleration =>         100},
                  {:max_speed    => 1000000000000,
                   :acceleration =>           10},
                  {:max_speed    => 1000000000000,
                   :acceleration =>          100,
                   :speed        =>     50000000},
                  {:max_speed    =>  100000000000,
                   :speed        =>   10000000000,
                   :acceleration =>            10}]

      position = [{:coordinates  => build(:location).coordinates,
                   :orientation  => Motel.rand_vector,
                   :rot_theta    => rand * 2 * Math::PI,
                   :target       => build(:location).coordinates },

                  {:coordinates  => [1000000, 1000000, 1000000],
                   :orientation  => Motel.rand_vector,
                   :rot_theta    => rand * 2 * Math::PI,
                   :target       => [0, 0, 0]}]

      movement.each do |m|
        position.each do |p|
          data = p.merge m
          run_movement    data
          assert_arrived! data
        end
      end
    end
  end

  context "high linear to rotational movement ratio" do
    it "runs movement" do
      movement = [{:rot_theta    => Math::PI/32,
                   :max_speed    => 10000000,
                   :acceleration =>  1000000},

                  {:rot_theta    => Math::PI/64,
                   :max_speed    => 100000000,
                   :acceleration =>  10000000},

                  {:rot_theta    => Math::PI/128,
                   :max_speed    => 1000000000,
                   :acceleration =>   10000000},

                  {:rot_theta    => Math::PI/256,
                   :max_speed    => 10000000000,
                   :acceleration =>     1000000},

                  {:rot_theta    => Math::PI/1024,
                   :max_speed    => 1000000000000,
                   :acceleration =>     100000000},

                  {:rot_theta    => Math::PI/10240,
                   :max_speed    => 1000000000000,
                   :acceleration =>     100000000,
                   :speed        =>   50000000000},

                  {:rot_theta    => Math::PI/20480,
                   :max_speed    => 10000000000,
                   :acceleration =>        1000,
                   :speed        =>     9000000}]

      position = [{:coordinates  => build(:location).coordinates,
                   :orientation  => Motel.rand_vector,
                   :target       => build(:location).coordinates},

                  {:coordinates  => Motel.rand_vector.collect { |c| c * 10000000 },
                   :orientation  => Motel.rand_vector,
                   :target       => build(:location).coordinates},

                  {:coordinates  => [1000000000, 100000000, 1000000000],
                   :orientation  => Motel.rand_vector,
                   :target       => build(:location).coordinates},

                  {:coordinates  => Motel.rand_vector.collect { |c| c * 100 },
                   :orientation  => Motel.rand_vector,
                   :target       => build(:location).coordinates},

                  {:coordinates  => loc.coordinates,
                   :orientation  => Motel.rand_vector,
                   :target       => (loc + [10, 10, 10]).coordinates}]

      movement.each do |m|
        position.each do |p|
          data = p.merge m
          run_movement    data
          assert_arrived! data
        end
      end
    end
  end

  context "magnitude variance offsets initial calculation"

  context "discrete polling offsets initial calculation"

  context "previously failed cases" do
    it "now works" do
      data1 = { :coordinates  => [360, 870, 257],
                :orientation  => [-0.9138115486202573, 0.40613846605344767, 0.0],
                :target       => [672, -980, -762],
                :rot_theta    => 0.13408429258166701,
                :max_speed    => 325,
                :acceleration => 50}

      data2 = { :coordinates  => [317, 862, -190],
                :orientation  => [-0.6359987280038161, -0.741998516004452, -0.211999576001272],
                :target       => [-480, 597, -618],
                :rot_theta    => 4.689134240163139,
                :max_speed    => 845,
                :acceleration => 39}

      data3 = { :coordinates  => [-762, -336, 260],
                :orientation  => [-0.5986710947139654, -0.5321520841901914, 0.5986710947139654],
                :target       => [683, -204, -298],
                :rot_theta    => 0.052178259610557144,
                :max_speed    => 8307,
                :acceleration => 13464}

      data4 = { :coordinates  => [975, -382, -242],
                :orientation  => [0.4767312946227962, -0.5720775535473553, -0.6674238124719146],
                :target       => [-627, -1000, 778],
                :rot_theta    => 0.015000184878763324,
                :max_speed    => 71050,
                :acceleration => 91481}

      data5 = { :coordinates  => [173, -508, 432],
                :orientation  => [0.4082482904638631, -0.4082482904638631, 0.8164965809277261],
                :target       => [680, 13, -641],
                :rot_theta    => 0.010447437519145342,
                :max_speed    => 7344,
                :acceleration => 31005}

      data6 = {:coordinates   => [-64, 656, 208],
               :orientation   => [0.7662610281769211, 0.2873478855663454, 0.5746957711326908],
               :target        => [21, -307, -185],
               :rot_theta     => 4.195765518629954,
               :max_speed     => 965,
               :acceleration  => 94883 }

      run_movement    data1
      assert_arrived! data1

      run_movement    data2
      assert_arrived! data2

      run_movement    data3
      assert_arrived! data3

      run_movement    data4
      assert_arrived! data4

      run_movement    data5
      assert_arrived! data5

      run_movement    data6
      assert_arrived! data6
    end
  end
end # describe Towards
end # module Motel::MovementStrategies
