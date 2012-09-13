#!/usr/bin/ruby
# a full simulation universe
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# FIXME replace random axis + rand locations

require 'rubygems'
require 'omega'

include Omega::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO
login 'admin',  :password => 'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => Location.new(:x => 240, :y => -360, :z => 110) do |sys|
    planet 'Posseidon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.6, :semi_latus_rectum => 150,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Posseidon I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon III', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon IV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hermes',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.3, :semi_latus_rectum => 169,
                                                :direction => Motel.random_axis)

    planet 'Apollo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.8, :semi_latus_rectum => 100,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Apollo V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Apollo VII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hades',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.9, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hades III',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades V',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VII',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VIII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades IX',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XII',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XIII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XIV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Aphrodite', 'V866', :location => Location.new(:x => -420, :y => 119, :z => 90) do |sys|
    planet 'Xenon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.8, :semi_latus_rectum => 110,
                                                :direction => Motel.random_axis)
    planet 'Aesop',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.55, :semi_latus_rectum => 150,
                                                :direction => Motel.random_axis)
    planet 'Cleopatra',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis)
    planet 'Demon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 129,
                                                :direction => Motel.random_axis)
    planet 'Lynos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.3125, :semi_latus_rectum => 131,
                                                :direction => Motel.random_axis)
    planet 'Heracules',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.49, :semi_latus_rectum => 110,
                                                :direction => Motel.random_axis)
    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Theodosia', 'ST9098', :location => Location.new(:x => 412, :y => -132, :z => 342) do |sys|
    planet 'Eukleides',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.21, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis)

    planet 'Phoibe',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.1, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Phiobe V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Phiobe VI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Basilius',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Basilius V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius VI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XII', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XIII',:location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XX',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XXI', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Leonidas',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.55, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Leonidas V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Pythagoras',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.66, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Pythagoras V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Pythagoras VI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Zeno',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.15, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Zeno I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Zeno II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Zeno III', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Galene',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.62, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis)
  end

  system 'Nike', 'QR1515', :location => Location.new(:x => -222, :y => 333, :z => 413) do |sys|
    planet 'Nike I',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.12, :semi_latus_rectum => 115,
                                                :direction => Motel.random_axis)
    planet 'Nike II',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.94, :semi_latus_rectum => 143,
                                                :direction => Motel.random_axis)
    planet 'Nike III',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis)
    planet 'Nike IV',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.13, :semi_latus_rectum => 130,
                                                :direction => Motel.random_axis)
    planet 'Nike V',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.291, :semi_latus_rectum => 155,
                                                :direction => Motel.random_axis)
    planet 'Nike VI',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.388, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis)
    planet 'Nike VII',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.77, :semi_latus_rectum => 154,
                                                :direction => Motel.random_axis)
    planet 'Nike VIII',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.22, :semi_latus_rectum => 134,
                                                :direction => Motel.random_axis)
    planet 'Nike IX',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.32, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis)
    planet 'Nike X',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.64, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis)
  end

  system 'Philo', 'HU1792', :location => Location.new(:x => -142, :y => -338, :z => 409) do |sys|
    planet 'Theophila',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.88, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Theophila X',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Theophila XI',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Theophila XII',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Zosime',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.25, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Zosime I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Xeno',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 140,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Xeno I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Xeno II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }

  end

  system 'Aphroditus', 'V866', :location => Location.new(:x => -420, :y => 119, :z => 90) do |sys|
    planet 'Xenux',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.8, :semi_latus_rectum => 110,
                                                :direction => Motel.random_axis)
    planet 'Aesop',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :e => 0.7, :p => 124, :direction => Motel.random_axis)
  end

  system 'Irene', 'HZ1279', :location => Location.new(:x => 110, :y => 423, :z => -455) do |sys|
    planet 'Irene I',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.29, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis)
    planet 'Irene II',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.40, :semi_latus_rectum => 163,
                                                :direction => Motel.random_axis)
    planet 'Korinna',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.71, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis)
    planet 'Gaiane',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.68, :semi_latus_rectum => 155,
                                                :direction => Motel.random_axis)
    planet 'Demetrius',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.223, :semi_latus_rectum => 170,
                                                :direction => Motel.random_axis)
  end

  system 'Phokas', 'LO0032', :location => Location.new(:x => 112, :y => 485, :z => 165) do |sys|
    planet 'Akea',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Akea I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Photina', 'A99G4', :location => Location.new(:x => 112, :y => 485, :z => 165) do |sys|
  end

  system 'Zosimus', 'GJ929J', :location => Location.new(:x => -122, :y => 553, :z => -194) do |sys|
  end

  system 'Demetrium', 'HGH902', :location => Location.new(:x => 342, :y => 95, :z => -98) do |sys|
  end

  system 'Dorisi', 'HF092N', :location => Location.new(:x => 34, :y => -33, :z => 34) do |sys|
  end

  system 'Syntyche', 'PP2942', :location => Location.new(:x => 432, :y => 646, :z => -174) do |sys|
  end

  system 'Aristocoles', 'GH29BV9', :location => Location.new(:x => 48, :y => -184, :z => -208) do |sys|
  end
end

jump_gate system('Athena'), system('Aphrodite'), :location => Location.new(:x => -150, :y => -150, :z => -150)
jump_gate system('Athena'), system('Philo'),     :location => Location.new(:x => 150, :y => 150, :z => 150)

galaxy 'Hera' do |g|
  system 'Agathon', 'JJ7192', :location => Location.new(:x => -88, :y => 219, :z => 499) do |sys|
    planet 'Tychon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tyhon I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Tyhon II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Pegasus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Pegas',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Olympos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.52, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis)

    planet 'Zotikos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.31, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis)

    planet 'Zopyros',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.66, :semi_latus_rectum => 151,
                                                :direction => Motel.random_axis)

    planet 'Kallisto',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.46, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Myrrine',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eugenia',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Doris',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Draco',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dion',      :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Elpis',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Isocrates', 'IL9091', :location => Location.new(:x => -104, :y => -399, :z => -438) do |sys|
    planet 'Isocrates I',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 136,
                                                :direction => Motel.random_axis)

    planet 'Isocrates II',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 136,
                                                :direction => Motel.random_axis)

    planet 'Isocrates III',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 136,
                                                :direction => Motel.random_axis)
  end

  system 'Thais', 'QR1021', :location => Location.new(:x => 116, :y => 588, :z => -91) do |sys|
    planet 'Rhode',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.5, :semi_latus_rectum => 145,
                                                :direction => Motel.random_axis)
  end

  system 'Timon', 'FZ6675', :location => Location.new(:x => 88, :y => 268, :z => 91)
  system 'Zoe',   'FR7751', :location => Location.new(:x => -81, :y => -178, :z => -381)
  system 'Myron', 'RZ9901', :location => Location.new(:x => 498, :y => -114, :z => 101)

  system 'Lysander', 'V21', :location => Location.new(:x => 231, :y => 112, :z => 575) do |sys|
    planet 'Lysandra',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.46, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lysandra I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Lysandra II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Lysandrus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.49, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lysandrus I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Lysandrene',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.66, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lysandrene I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Pelagia', 'HR1001', :location => Location.new(:x => -212, :y => -321, :z => 466) do |sys|
    planet 'Iason',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.48, :semi_latus_rectum => 143,
                                                :direction => Motel.random_axis)
    planet 'Dionysius',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.69, :semi_latus_rectum => 158,
                                                :direction => Motel.random_axis)
  end

  system 'Pericles', 'ST5309', :location => Location.new(:x => -156, :y => -341, :z => -177)
  system 'Sophia',   'ST5310', :location => Location.new(:x => 266, :y => -255, :z => -244)
  system 'Theodora', 'ST5311', :location => Location.new(:x => 500, :y => 118, :z => 326)

  system 'Tycho', 'Q931', :location => Location.new(:x => 420, :y => -420, :z => 420) do |sys|
    planet 'Agape',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 144,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Agape I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Agape II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Argyros',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Argyrosa I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Argyrosus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.55, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis)

    planet 'Hero',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hero I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero III', :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero IV',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Stephanos', 'ST111', :location => Location.new(:x => 51, :y => -63, :z => 500)

  system 'Kleon', 'ST223', :location => Location.new(:x => -112, :y => -642, :z => -119) do |sys|
  end

  system 'Zenobia', 'ST812', :location => Location.new(:x => -598, :y => -575, :z => -204) do |sys|
  end

  system 'Panther', 'ST0245', :location => Location.new(:x => -819, :y => 102, :z => 844) do |sys|
  end

  system 'Xenia', 'ST0482', :location => Location.new(:x => 193, :y => -339, :z => -449) do |sys|
  end

  system 'Thales', 'ST0572', :location => Location.new(:x => -953, :y => 285, :z => 475) do |sys|
  end

  system 'Nikias', 'ST875', :location => Location.new(:x => 305, :y => 438, :z => 308) do |sys|
  end

  system 'Metrodora', 'ST875', :location => Location.new(:x => 305, :y => 438, :z => 308) do |sys|
  end

  system 'Lycus', 'ST022', :location => Location.new(:x => -254, :y => 459, :z => -335) do |sys|
  end

  system 'Epaphras', 'ST230', :location => Location.new(:x => 554, :y => 244, :z => -495) do |sys|
  end

  system 'Eugina', 'ST011', :location => Location.new(:x => -334, :y => -53, :z => 45) do |sys|
  end
end

galaxy 'Thor' do |g|
  system 'Loki', 'B78915', :location => Location.new(:x => 57, :y => -530, :z => -116) do |sys|
    planet 'Hermod',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 180,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hermod I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hermod II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)

      0.upto(50){
        asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
          resource :resource => rand_resource, :quantity => 500
        end
      }
    end
  end

  system 'Heimdall', 'ABBA89', :location => Location.new(:x => 65, :y => -232, :z => 221) do |sys|
  end

  system 'Modi', 'FFBBA4', :location => Location.new(:x => 189, :y => 420, :z => -112) do |sys|
  end

  system 'Nanna', 'BCCC69', :location => Location.new(:x => -545, :y => 953, :z => 843) do |sys|
  end

  system 'Fulla', 'DB0990', :location => Location.new(:x => 303, :y => 304, :z => -203) do |sys|
  end

  system 'Nidhogg', 'DB0880', :location => Location.new(:x => -303, :y => -304, :z => 203) do |sys|
  end

  system 'Tyr', 'DDCB78', :location => Location.new(:x => 645, :y => 756, :z => 354) do |sys|
  end

  system 'Ran', 'DDCB77', :location => Location.new(:x => 755, :y => 656, :z => 200) do |sys|
  end

  system 'Var', 'DDCB76', :location => Location.new(:x => 834, :y => 578, :z => 253) do |sys|
  end

  system 'Ymi', 'DDCB75', :location => Location.new(:x => 776, :y => 644, :z => 344) do |sys|
  end
end

galaxy 'Odin' do |g|
  system 'Asgrad', 'FE8331', :location => Location.new(:x => 253, :y => -753, :z => -112) do |sys|
  end

  system 'Valhalla', 'FE9782', :location => Location.new(:x => -10, :y => -523, :z => -492) do |sys|
  end

  system 'Hel', 'FE7334', :location => Location.new(:x => 57, :y => 115, :z => 432) do |sys|
  end

  system 'Runic', 'FE7AA1', :location => Location.new(:x => 785, :y => 899, :z => 845) do |sys|
  end

  system 'Saga', 'FE7AA2', :location => Location.new(:x => -822, :y => 910, :z => -734) do |sys|
  end

  system 'Jord', 'FE7AA3', :location => Location.new(:x => -999, :y => 456, :z => 650) do |sys|
  end

  system 'Norn', 'FE7AA4', :location => Location.new(:x => 921, :y => 880, :z => -820) do |sys|
  end

  system 'Ogres', 'FE7AA5', :location => Location.new(:x => 888, :y => -777, :z => -666) do |sys|
  end

  system 'Ulle', 'FE7AA6', :location => Location.new(:x => 807, :y => -749, :z => 850) do |sys|
  end

  system 'Njord', 'FE7AA7', :location => Location.new(:x => 909, :y => 808, :z => -853) do |sys|
  end

  system 'Syn', 'FE7AA8', :location => Location.new(:x => -935, :y => -942, :z => -908) do |sys|
  end

  system 'Skadi', 'FE7AA9', :location => Location.new(:x => 993, :y => 922, :z => -807) do |sys|
  end

  system 'Ogres', 'FE7AAA', :location => Location.new(:x => 888, :y => -767, :z => 909) do |sys|
  end

  system 'Ulle', 'FE7AAB', :location => Location.new(:x => 804, :y => -709, :z => -809) do |sys|
  end

  system 'Surtr', 'FE7AAC', :location => Location.new(:x => 974, :y => -973, :z => 775) do |sys|
  end

  system 'Woden', 'FE7AAD', :location => Location.new(:x => 721, :y => 792, :z => -856) do |sys|
  end

  system 'Hermod', 'FE7AAE', :location => Location.new(:x => -978, :y => -898, :z => -859) do |sys|
  end

  system 'Hlin', 'FE7AAF', :location => Location.new(:x => -721, :y => 998, :z => 889) do |sys|
  end
end

galaxy 'Freya' do |g|
  system 'Fenrir', 'AA5521', :location => Location.new(:x => -323, :y => -360, :z => 369) do |sys|
    planet 'Gerd',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 180,
                                                :direction => Motel.random_axis) do
    end
  end

  system 'Vithar', 'BA4429', :location => Location.new(:x => -853, :y => 853, :z => 346) do |sys|
  end

  system 'Eir', 'ED0313', :location => Location.new(:x => -123, :y => 587, :z => 580) do |sys|
  end

  system 'Garm', 'AA3041', :location => Location.new(:x => 100, :y => 750, :z => 582) do |sys|
  end

  system 'Vili', 'DC5929', :location => Location.new(:x => 820, :y => -351, :z => 922) do |sys|
  end

  system 'Gunlad', 'FF2002', :location => Location.new(:x => 220, :y => 773, :z => -667) do |sys|
  end

  system 'Edda', 'FF3003', :location => Location.new(:x => -515, :y => -623, :z => -112) do |sys|
  end
end
