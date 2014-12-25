# Motel Movement Integration Tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'

describe Motel do
  describe "face and move" do
    let(:ms) { Object.new.extend(Motel::MovementStrategies::LinearMovement)
                         .extend(Motel::MovementStrategies::Rotatable)
                         .extend(Motel::MovementStrategies::TracksCoordinates) }

    let(:tests) { 10      }
    let(:steps) { 500000  }
    let(:delay) { 0.01    }

    let(:fixed)   { { :distance_tolerance    => 1,
                      :orientation_tolerance => Math::PI / 128 } }
    let(:domains) { { :coords                => 100000000,
                      :target                => 100000000,
                      :acceleration          => 1000000,
                      :max_speed             => 1000000,
                      :speed                 => 1000000,
                      :rot_theta             => 2*Math::PI } }

    def run_test(lparams, mparams)
      loc = init_test(lparams, mparams)

      0.upto(steps) do |i|
        puts "Step #{i}:  #{state_str(loc)}"
        expect {
          move(loc, delay)
        }.to_not raise_error, error_out(lparams, mparams)
        break if ms.arrived?(loc)
      end

      verify!(loc, lparams, mparams)
    end

    def init_test(lparams, mparams)
      ms.distance_tolerance    = mparams[:distance_tolerance]
      ms.orientation_tolerance = mparams[:orientation_tolerance]
      ms.max_speed             = mparams[:max_speed]
      ms.acceleration          = mparams[:acceleration]
      ms.rot_theta             = mparams[:rot_theta]
      ms.target                = mparams[:target]
      ms.stop_near             = Array.new(mparams[:target]).unshift(1)
      ms.dir                   = mparams[:dir]
      ms.speed                 = mparams[:speed]
      build(:location, lparams)
    end

    def orient_str(loc)
      "O: #{loc.orientation.join(',')}"
    end

    def coords_str(loc)
      "C: #{loc.coordinates.join(',')}"
    end

    def dist_str(loc)
      "D: #{loc.distance_from(*ms.target)}"
    end

    def rot_str(loc)
      "R: #{ms.rotating?(loc)} / RO: #{ms.rotation_to_target(loc).first}"
    end

    def facing_str(loc)
      "F: #{ms.facing_target?(loc)}"
    end

    def speed_str
      "S: #{ms.speed}"
    end

    def vel_str
      "V: #{ms.dir}"
    end

    def lin_str
      "#{speed_str} #{vel_str}"
    end

    def projection(loc)
      c = loc.coordinates
      o = loc.orientation
      d = loc.distance_from(*ms.target)
      [c[0] + o[0] * d, c[1] + o[1] * d, c[2] + o[2] * d]
    end

    def proj_str(loc)
      p = projection(loc)
      "P: #{p[0].round_to(2)}, #{p[1].round_to(2)}, #{p[2].round_to(2)}"
    end

    def projection_diff(loc)
      p = projection(loc)
      Motel.length((p[0] - ms.target[0]).abs,
                   (p[1] - ms.target[1]).abs,
                   (p[2] - ms.target[2]).abs)
    end

    def proj_diff_str(loc)
      "PD: #{projection_diff(loc)}"
    end

    def state_str(loc)
      "#{dist_str(loc)} / #{proj_str(loc)} / #{proj_diff_str(loc)} / #{rot_str(loc)} / #{coords_str(loc)}"
    end

    def error_out(lparams, mparams)
      lparams.inspect + '/' + mparams.inspect
    end

    def move(loc, elapsed)
      oa = ms.acceleration
      ms.acceleration = nil unless ms.rotation_stopped?(loc)
      ms.move_linear(loc, elapsed)
      ms.acceleration = oa

      ms.face_target(loc)
      ms.rotate(loc, elapsed)
      ms.update_acceleration_from(loc)
      ms.update_dir_from(loc) if ms.facing_movement?(loc, ms.orientation_tolerance)
    end

    def verify!(loc, lparams, mparams)
      ms.arrived?(loc).should be_true, error_out(lparams, mparams)
    end

    def valid_rand(max)
      v = 0
      v = rand * max until v != 0
      v
    end

    it "arrives on target" do
      0.upto(tests) do
        lparams = {:x           => valid_rand(domains[:coords]),
                   :y           => valid_rand(domains[:coords]),
                   :z           => valid_rand(domains[:coords]),
                   :orientation => Motel.rand_vector}

        mparams = {:distance_tolerance    => fixed[:distance_tolerance],
                   :orientation_tolerance => fixed[:orientation_tolerance],
                   :max_speed             => valid_rand(domains[:max_speed]),
                   :acceleration          => valid_rand(domains[:acceleration]),
                   :rot_theta             => valid_rand(domains[:rot_theta]),
                   :target                => [valid_rand(domains[:target]),
                                              valid_rand(domains[:target]),
                                              valid_rand(domains[:target])],
                   :dir                   => Motel.rand_vector,
                   :speed                 => 1} #valid_rand(domains[:speed])

        run_test lparams, mparams
      end
    end

    context "previously failed cases" do
      it "now works" do
        lparams = {:x           =>  34179641,
                   :y           => 998249829,
                   :z           => 600659851,
                   :orientation =>[-0.6446583712203042, 0.7252406676228422, 0.24174688920761409]}

        mparams = {:distance_tolerance    => 1,
                   :orientation_tolerance => Math::PI/1024,
                   :max_speed             => 4589430,
                   :acceleration          => 8086300,
                   :rot_theta             => 1,
                   :target                => [934365395, 492380308, 595606598],
                   :speed                 => 1,
                   :dir                   => [0.8717657189324843, -0.4898986330954319, -0.00488472981402858]}

        run_test lparams, mparams

        lparams = {:x                     => 718614608.741208,
                   :y                     => 583567080.84811171,
                   :z                     => 328772079.48497005,
                   :orientation           => [0.0, 0.52999894000318, -0.847998304005088]}
        mparams = {:distance_tolerance    => 1,
                   :orientation_tolerance => 0.02454369260617026,
                   :max_speed             => 104666.76187535717,
                   :acceleration          => 197477.6827303264,
                   :rot_theta             => 1.2132918867307356,
                   :target                => [536915356.1720995,
                                              646475781.2665235,
                                              441114931.08252895],
                   :dir                   => [0.0, -0.7592566023652966, -0.6507913734559685],
                   :speed                 => 1}

        run_test lparams, mparams

        lparams = {:x                     => 93312409.35536967,
                   :y                     => 97016040.27220297,
                   :z                     => 18593735.16128072,
                   :orientation           => [-0.211999576001272, 0.211999576001272, 0.953998092005724]}
                    
        mparams = {:distance_tolerance    => 1,
                   :orientation_tolerance => 0.02454369260617026,
                   :max_speed             => 936335.5354775746,
                   :acceleration          => 419173.52562614053,
                   :rot_theta             => 4.702099397390806,
                   :target                => [17354930.91527178, 83823920.60166006, 41382565.87571455],
                   :dir                   => [-0.9363291775690445, 0.0, -0.3511234415883917],
                   :speed                 => 1}

        run_test lparams, mparams
      end
    end
  end
end # describe Motel
