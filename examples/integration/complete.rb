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

    planet 'Apukohai',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Aphukohai I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Haulili',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.13, :semi_latus_rectum => 142,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Haulili I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Haulili II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hiaka',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.72, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hiaka I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kalaipahoa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.39, :semi_latus_rectum => 168,
                                                :direction => Motel.random_axis)
    planet 'Kamapua',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.65, :semi_latus_rectum => 118,
                                                :direction => Motel.random_axis)

    planet 'Kamooalii',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.88, :semi_latus_rectum => 162,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kamooalii I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kamooalii II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kamooalii III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kamooalii IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kamooalii V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kanaloa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 145,
                                                :direction => Motel.random_axis)

    planet 'Kane',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.88, :semi_latus_rectum => 155,
                                                :direction => Motel.random_axis)

    planet 'Kapo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.32, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kapo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kapo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Photina', 'A99G4', :location => Location.new(:x => 112, :y => 485, :z => 165) do |sys|
    planet 'Keuakepo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.50, :semi_latus_rectum => 138,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Keuakepo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Keuakepo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kiha',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.73, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kiha I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kiha II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ku',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.13, :semi_latus_rectum => 166,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ku I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ku II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ku III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kaupe',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.13, :semi_latus_rectum => 166,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kaupe I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kaupe II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kaupe III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kuula',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis)

    planet 'Laka',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 174,
                                                :direction => Motel.random_axis)

    planet 'Lie',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis)

    planet 'Lono',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Lono I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Maui',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.82, :semi_latus_rectum => 156,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Maui I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Maui II',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ouli',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.48, :semi_latus_rectum => 144,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ouli I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ouli II',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ouli III',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Polihau',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.75, :semi_latus_rectum => 158,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Polihau I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Papa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.67, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis)

    planet 'Pele',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.44, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis)

    planet 'Uli',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 177,
                                                :direction => Motel.random_axis)

    0.upto(150){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Zosimus', 'GJ929J', :location => Location.new(:x => -122, :y => 553, :z => -194) do |sys|
    planet 'Airmid',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis)

    planet 'Balor',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.92, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis)

    planet 'Camalus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.24, :semi_latus_rectum => 176,
                                                :direction => Motel.random_axis)

    planet 'Druantia',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 173,
                                                :direction => Motel.random_axis)

    planet 'Lugh',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 146,
                                                :direction => Motel.random_axis)

    planet 'Llyr',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis)

    planet 'Maeve',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 143,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Maeve I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Maeve II',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Maeve III',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Mebd',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.76, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Mebd I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mebd II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mebd III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mebd IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mebd V',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Mider',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.79, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Mider I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mider II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mider III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mider IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Morrigan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.24, :semi_latus_rectum => 142,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Morrigan I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Morrigan II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Morrigan III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Morrigan IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Nemian',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 164,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nemian I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nemian II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Aine',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.78, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Aine I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Aine II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Anu',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.39, :semi_latus_rectum => 172,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Anu I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Demetrium', 'HGH902', :location => Location.new(:x => 342, :y => 95, :z => -98) do |sys|
    planet 'Bel',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.88, :semi_latus_rectum => 154,
                                                :direction => Motel.random_axis)

    planet 'Bran',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 134,
                                                :direction => Motel.random_axis)

    planet 'Bris',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.43, :semi_latus_rectum => 198,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Bris I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Bris II',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Bris III',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Dagda',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.57, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dagda I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dagda II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dagda III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dagda IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dagda V',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Diancecht',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.69, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Diancecht I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Diancecht II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Diancecht III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Diancecht IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Flidais',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.68, :semi_latus_rectum => 168,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Flidais I',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Flidais II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Flidais III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Flidais IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Dorisi', 'HF092N', :location => Location.new(:x => 34, :y => -33, :z => 34) do |sys|
    planet 'Macha',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.54, :semi_latus_rectum => 176,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Macha I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Macha II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Niamh',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 156,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Niamh I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Arawn',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.89, :semi_latus_rectum => 138,
                                                :direction => Motel.random_axis)

    planet 'Blodeuwedd',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.17, :semi_latus_rectum => 129,
                                                :direction => Motel.random_axis)

    planet 'Dewi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 197,
                                                :direction => Motel.random_axis)

    planet 'Don',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Don I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Don II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Don III',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Don IV',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Don V',      :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Don VI',     :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(250){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Syntyche', 'PP2942', :location => Location.new(:x => 432, :y => 646, :z => -174) do |sys|
    planet 'Dylan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.93, :semi_latus_rectum => 112,
                                                :direction => Motel.random_axis)

    planet 'Elaine',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 172,
                                                :direction => Motel.random_axis)

    planet 'Gwydion',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.44, :semi_latus_rectum => 132,
                                                :direction => Motel.random_axis)

    planet 'Myrrdin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.78, :semi_latus_rectum => 115,
                                                :direction => Motel.random_axis)

  end

  system 'Aristocoles', 'GH29BV9', :location => Location.new(:x => 48, :y => -184, :z => -208) do |sys|
    planet 'Aizen-Myoo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.25, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis)

    planet 'Amatsu-Kami',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Amatsu-Kami I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Amatsu-Kami II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Amatsu-Kami III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Amatsu-Kami IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Amatsu-Kami V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Amatsu-Kami VI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Amatsu-Kami VII',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Butsu',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 155,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Butsu I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
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
    planet 'Chien-shin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 132,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Chien-shin I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Chien-shin II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Chup-Kamui',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.25, :semi_latus_rectum => 128,
                                                :direction => Motel.random_axis)

    planet 'Daikoku',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.54, :semi_latus_rectum => 137,
                                                :direction => Motel.random_axis)

    planet 'Dosojin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.44, :semi_latus_rectum => 140,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dosojin I',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ebisu',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 157,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ebisu I',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ebisu II',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ebisu III',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Zenobia', 'ST812', :location => Location.new(:x => -598, :y => -575, :z => -204) do |sys|
    planet 'Fudo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.87, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Fudo I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Fudo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Fudo III',  :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Fudo IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Fujin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.88, :semi_latus_rectum => 111,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Fujin I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Fujin II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Funadama',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.96, :semi_latus_rectum => 115,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Funadama I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Gama',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.50, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis)

    planet 'Hachiman',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.30, :semi_latus_rectum => 144,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hachiman I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hachiman II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hachiman III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hiruko',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 145,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hiruko I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hotei',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.67, :semi_latus_rectum => 188,
                                                :direction => Motel.random_axis)

    planet 'Ida-Ten',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.56, :semi_latus_rectum => 104,
                                                :direction => Motel.random_axis)
  end

  system 'Panther', 'ST0245', :location => Location.new(:x => -819, :y => 102, :z => 844) do |sys|
    planet 'Iki-Ryo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.69, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Inari',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.89, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Isora',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.84, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Isora I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Isora II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Izanagi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.47, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Izanagi I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Izanagi II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Izanami',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.28, :semi_latus_rectum => 75,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Izanami I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Izanami II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Izanami III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Jizo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.57, :semi_latus_rectum => 74,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Kaminari',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.67, :semi_latus_rectum => 174,
                                                :direction => Motel.random_axis) do |pl|
    end
  end

  system 'Xenia', 'ST0482', :location => Location.new(:x => 193, :y => -339, :z => -449) do |sys|
    planet 'Kojin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.84, :semi_latus_rectum => 178,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Koshin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Koshin I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kura-Okami',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.17, :semi_latus_rectum => 42,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Miro',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 103,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Nai-no-Kami',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 142,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nai-no-Kami I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Nikko-Bosatsu",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.52, :semi_latus_rectum => 142,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nikko-Bosatsu I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nikko-Bosatsu II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nikko-Bosatsu III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Nyorai",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.29, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nyorai I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nyorai II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nyorai III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nyorai IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nyorai V',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Thales', 'ST0572', :location => Location.new(:x => -953, :y => 285, :z => 475) do |sys|
    planet "Oanomochi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.10, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Oanomochi I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Oanomochi II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Oanomochi III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Oho-Yama",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.34, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Oho-Yama I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Oho-Yama II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Owatatsumi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.34, :semi_latus_rectum => 102,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Raiden",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.29, :semi_latus_rectum => 154,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Raiden I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Sambo-kojin",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.58, :semi_latus_rectum => 155,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Sarutahiko",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.24, :semi_latus_rectum => 143,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Sarutahiko I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Sarutahiko II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Sarutahiko III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Sarutahiko IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Sengen",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.93, :semi_latus_rectum => 103,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Shaka",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.11, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Shichi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.54, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Shichi I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Shinda",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.58, :semi_latus_rectum => 188,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Shinda I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Shoden",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Shoki",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.64, :semi_latus_rectum => 109,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Shoki I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Shoki II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Nikias', 'ST875', :location => Location.new(:x => 305, :y => 438, :z => 308) do |sys|
    planet "Suijin",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.77, :semi_latus_rectum => 119,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Suijin I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Suitengu",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Suitengu I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Susanowa",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.38, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Takemikadzuchi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.10, :semi_latus_rectum => 193,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Takemikadzuchi I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Tenjin",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.03, :semi_latus_rectum => 117,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tenjin I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Tsuki-Yumi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 164,
                                                :direction => Motel.random_axis) do |pl|
    end
  end

  system 'Metrodora', 'ST875', :location => Location.new(:x => 305, :y => 438, :z => 308) do |sys|
    planet "Uba",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.24, :semi_latus_rectum => 194,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Uba I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Uba II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Uba III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Uga-Jin",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.19, :semi_latus_rectum => 136,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Uga-Jin I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Uga-Jin I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Ukemochi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.99, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Uzume",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.75, :semi_latus_rectum => 124,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Yabune",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 103,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Yabune I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Yamato",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.25, :semi_latus_rectum => 132,
                                                :direction => Motel.random_axis) do |pl|
    end
  end

  system 'Lycus', 'ST022', :location => Location.new(:x => -254, :y => 459, :z => -335) do |sys|
    planet "Afa",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.12, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Ao",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 143,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ao I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Ara",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.459, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Atea",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.19, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Atea I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Epaphras', 'ST230', :location => Location.new(:x => 554, :y => 244, :z => -495) do |sys|
    planet "Atua",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.56, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet "Atutahi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 172,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Atutahi I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Awha",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 192,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Awha I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Awha II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Dhakhan",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.32, :semi_latus_rectum => 132,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dhakhan I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dhakhan II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Julana",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.65, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Julana I',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Julana II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Julana III',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Julana IV',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Eugina', 'ST011', :location => Location.new(:x => -334, :y => -53, :z => 45) do |sys|
    planet "Karora",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.43, :semi_latus_rectum => 142,
                                                :direction => Motel.random_axis)
    planet "Njirana",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.89, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis)
    planet "Pundjel",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.19, :semi_latus_rectum => 154,
                                                :direction => Motel.random_axis)
    planet "Ungud",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.89, :semi_latus_rectum => 198,
                                                :direction => Motel.random_axis)
    planet "Anjea",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.165, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis)
    planet "Dilga",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.140, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis)
    planet "Gnowee",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis)
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
    end

    planet "Wala",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.67, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis)

    planet "Yhi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 113,
                                                :direction => Motel.random_axis)

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Heimdall', 'ABBA89', :location => Location.new(:x => 65, :y => -232, :z => 221) do |sys|
    planet 'Abaangui',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis)

    planet 'Achi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 183,
                                                :direction => Motel.random_axis)

    planet 'Achomawi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 133,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Achomawi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Achomawi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Aguara',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.94, :semi_latus_rectum => 183,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Aguara I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ahayuta',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.92, :semi_latus_rectum => 132,
                                                :direction => Motel.random_axis)

    planet 'Ahea',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.76, :semi_latus_rectum =>164,
                                                :direction => Motel.random_axis)

    planet 'Aholi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Aholi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Aholi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Aholi III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Akna',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.47, :semi_latus_rectum => 173,
                                                :direction => Motel.random_axis)

    planet 'Aluet',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 198,
                                                :direction => Motel.random_axis)
  end

  system 'Modi', 'FFBBA4', :location => Location.new(:x => 189, :y => 420, :z => -112) do |sys|
    planet 'Alignak',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.93, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Alignak I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Alkuntam',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.41, :semi_latus_rectum => 129,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Alkuntam I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Amala',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.27, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis)

    planet 'Amitolane',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.72, :semi_latus_rectum => 153,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Amitolane I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Amotken',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.81, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Amotken I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Anaye',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.10, :semi_latus_rectum => 165,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Anaye I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anaye II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anaye II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anaye IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anaye V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anaye VI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Nanna', 'BCCC69', :location => Location.new(:x => -545, :y => 953, :z => 843) do |sys|
    planet 'Angalkuq',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.218, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Angalkuq I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Angokoq',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.03, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Angokoq I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Anguta',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.98, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Anguta I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anguta II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Anguta III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Aningan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.70, :semi_latus_rectum => 183,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Aningan I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Aningan II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Apikunni',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.48, :semi_latus_rectum => 130,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Apikunni I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Apisirahts',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.70, :semi_latus_rectum => 122,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Apisirahts I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Apotamkin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.34, :semi_latus_rectum => 110,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Apotamkin I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Apotamkin II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Apotamkin III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Apotamkin IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Fulla', 'DB0990', :location => Location.new(:x => 303, :y => 304, :z => -203) do |sys|
    planet 'Ataensic',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.68, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ataensic I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Awanawilonais',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.67, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Awanawilonais I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Awanawilonais II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Awonawilona',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.52, :semi_latus_rectum => 103,
                                                :direction => Motel.random_axis)

    planet 'Badger',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.39, :semi_latus_rectum => 164,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Badger I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Badger II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Begocidi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.73, :semi_latus_rectum => 172,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Begocidi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Bikeh Hozho',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.93, :semi_latus_rectum => 129,
                                                :direction => Motel.random_axis)

    planet 'Binaye Ahani',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.57, :semi_latus_rectum => 128,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Binaye Ahani I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Binaye Ahani II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Binaye Ahani III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Nidhogg', 'DB0880', :location => Location.new(:x => -303, :y => -304, :z => 203) do |sys|
    planet 'Bokwus',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.421, :semi_latus_rectum =>174,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Bokwus I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Bototo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 109,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Bototo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Capa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.64, :semi_latus_rectum => 163,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Capa I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Chacomat',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.49, :semi_latus_rectum => 123,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Chacomat I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Chacopa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.31, :semi_latus_rectum => 175,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Chacopa I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Tyr', 'DDCB78', :location => Location.new(:x => 645, :y => 756, :z => 354) do |sys|
    planet 'Chehooit',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.01, :semi_latus_rectum =>104,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Chehooit I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Chehooit II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Chibiabos',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.20, :semi_latus_rectum => 188R,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Chibiabos I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Chibiabos II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Chibiabos III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Chulyen',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.93, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Chulyen I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Chulyen II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Dajoji',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.44, :semi_latus_rectum => 130,
                                                :direction => Motel.random_axis)

    planet 'Dawn',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.48, :semi_latus_rectum => 127,
                                                :direction => Motel.random_axis)

    planet 'Dayunsi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.57, :semi_latus_rectum => 102,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dayunsi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dayunsi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Dohkwibuhch',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.20, :semi_latus_rectum => 158,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dohkwibuhch I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dohkwibuhch II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Ran', 'DDCB77', :location => Location.new(:x => 755, :y => 656, :z => 200) do |sys|
    planet 'Doquebuth',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.76, :semi_latus_rectum => 192,
                                                :direction => Motel.random_axis)

    planet 'Dzelarhons',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 177,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dzelarhons I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Dzoavits',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.30, :semi_latus_rectum => 102,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Dzoavits I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ehlaumel',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 149,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ehlaumel I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ehlaumel II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Eithinoha',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.449, :semi_latus_rectum => 172,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Eithinoha I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eithinoha II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eithinoha III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eithinoha IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eithinoha V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Var', 'DDCB76', :location => Location.new(:x => 834, :y => 578, :z => 253) do |sys|
    planet 'Enumclaw',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.40, :semi_latus_rectum => 162,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Enumclaw I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Eototo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.28, :semi_latus_rectum => 134,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Eototo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Estanatlehi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.75, :semi_latus_rectum => 156,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Estanatlehi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ewah',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.98, :semi_latus_rectum => 199,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ewah I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Ymi', 'DDCB75', :location => Location.new(:x => 776, :y => 644, :z => 344) do |sys|
    planet 'Ga Oh',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.34, :semi_latus_rectum => 127,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ga Oh I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Gaan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 159,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Gaan I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Gahe',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 103,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Gahe I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Gaoh',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.64, :semi_latus_rectum => 128,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Gaoh I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Glooscap',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.42, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Glooscap I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Gluscabi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.43, :semi_latus_rectum => 102,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Gluscabi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
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
