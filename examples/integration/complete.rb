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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end
end

jump_gate system('Athena'),      system('Aphrodite'),   :location => Location.new(:x => -150, :y => -150, :z => -150)
jump_gate system('Athena'),      system('Philo'),       :location => Location.new(:x => 150,  :y => 150,  :z => 150)
jump_gate system('Philo'),       system('Nike'),        :location => Location.new(:x => -192, :y => 429,  :z => 184)
jump_gate system('Nike'),        system('Phokas'),      :location => Location.new(:x => 160,  :y => 432,  :z => 524)
jump_gate system('Phokas'),      system('Dorisi'),      :location => Location.new(:x => 150,  :y => -160, :z => 223)
jump_gate system('Nike'),        system('Dorisi'),      :location => Location.new(:x => -539, :y => -283, :z => -188)
jump_gate system('Nike'),        system('Syntyche'),    :location => Location.new(:x => -472, :y => -385, :z => -223)
jump_gate system('Nike'),        system('Theodosia'),   :location => Location.new(:x => 655,  :y => 335,  :z => 390)
jump_gate system('Dorisi'),      system('Aristocoles'), :location => Location.new(:x => 567,  :y => -511, :z => 534)
jump_gate system('Aristocoles'), system('Philo'),       :location => Location.new(:x => 112,  :y => -132, :z => -545)
jump_gate system('Dorisi'),      system('Aphroditus'),  :location => Location.new(:x => 436,  :y => 123,  :z => 529)
jump_gate system('Aphroditus'),  system('Athena'),      :location => Location.new(:x => -334, :y => -139, :z => -148)
jump_gate system('Dorisi'),      system('Aristocoles'), :location => Location.new(:x => 353,  :y => 75,   :z => -353)
jump_gate system('Aphrodite'),   system('Aphroditus'),  :location => Location.new(:x => -109, :y => -384, :z => -132)
jump_gate system('Theodosia'),   system('Irene'),       :location => Location.new(:x => 484,  :y => -103, :z => -332)
jump_gate system('Irene'),       system('Photina'),     :location => Location.new(:x => -364, :y => 444,  :z => -274)
jump_gate system('Photina'),     system('Syntyche'),    :location => Location.new(:x => -454, :y => 399,  :z => 167)
jump_gate system('Syntyche'),    system('Photina'),     :location => Location.new(:x => 629,  :y => 588,  :z => 499)
jump_gate system('Irene'),       system('Zosimus'),     :location => Location.new(:x => -498, :y => -603, :z => 579)
jump_gate system('Zosimus'),     system('Demetrium'),   :location => Location.new(:x => 520,  :y => 102,  :z => 432)
jump_gate system('Demetrium'),   system('Athena'),      :location => Location.new(:x => 675,  :y => 576,  :z => -586)

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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 1500
      end
    }
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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 750
      end
    }
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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 450
      end
    }
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
      moon 'Uga-Jin II',    :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
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
    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 2000
      end
    }
  end
end

jump_gate system('Agathon'),      system('Isocrates'), :location => Location.new(:x => -132, :y => 394,  :z => -417)
jump_gate system('Isocrates'),    system('Thais'),     :location => Location.new(:x => 351,  :y => 141,  :z => -121)
jump_gate system('Thais'),        system('Timon'),     :location => Location.new(:x => 447,  :y => -108, :z => -202)
jump_gate system('Thais'),        system('Epaphras'),  :location => Location.new(:x => -130, :y => 327,  :z => -261)
jump_gate system('Timon'),        system('Myron'),     :location => Location.new(:x => 182,  :y => -464, :z => 361)
jump_gate system('Timon'),        system('Pelagia'),   :location => Location.new(:x => -24,  :y => -61,  :z => 454)
jump_gate system('Myron'),        system('Lysander'),  :location => Location.new(:x => 297,  :y => -403, :z => -206)
jump_gate system('Myron'),        system('Thales'),    :location => Location.new(:x => -345, :y => 192,  :z => -107)
jump_gate system('Myron'),        system('Nikias'),    :location => Location.new(:x => 67,   :y => -224, :z => -328)
jump_gate system('Pelagia'),      system('Pericles'),  :location => Location.new(:x => 208,  :y => -204, :z => 82)
jump_gate system('Pelagia'),      system('Tycho'),     :location => Location.new(:x => -401, :y => -188, :z => -105)
jump_gate system('Pelagia'),      system('Kleon'),     :location => Location.new(:x => -51,  :y => 273,  :z => 141)
jump_gate system('Pericles'),     system('Theodora'),  :location => Location.new(:x => -343, :y => 408,  :z => 361)
jump_gate system('Theodora'),     system('Tycho'),     :location => Location.new(:x => 17,   :y => -253, :z => 3)
jump_gate system('Theodora'),     system('Agathon'),   :location => Location.new(:x => -2,   :y => 467,  :z => 283)
jump_gate system('Tycho'),        system('Stephanos'), :location => Location.new(:x => 42,   :y => -8,   :z => -203)
jump_gate system('Tycho'),        system('Zenobia'),   :location => Location.new(:x => 463,  :y => 172,  :z => -207)
jump_gate system('Stephanos'),    system('Kleon'),     :location => Location.new(:x => -169, :y => -10,  :z => -498)
jump_gate system('Stephanos'),    system('Epaphras'),  :location => Location.new(:x => -316, :y => -495, :z => -455)
jump_gate system('Kleon'),        system('Zenobia'),   :location => Location.new(:x => 216,  :y => 321,  :z => -232)
jump_gate system('Kleon'),        system('Panther'),   :location => Location.new(:x => 474,  :y => 142,  :z => 99)
jump_gate system('Kleon'),        system('Xenia'),     :location => Location.new(:x => 353,  :y => -115, :z => -426)
jump_gate system('Zenobia'),      system('Panther'),   :location => Location.new(:x => -431, :y => -174, :z => 208)
jump_gate system('Panther'),      system('Xenia'),     :location => Location.new(:x => 10,   :y => 48,   :z => 488)
jump_gate system('Xenia'),        system('Thales'),    :location => Location.new(:x => 363,  :y => 241,  :z => -274)
jump_gate system('Thales'),       system('Nikias'),    :location => Location.new(:x => 86,   :y => -482, :z => -177)
jump_gate system('Nikias'),       system('Metrodora'), :location => Location.new(:x => -134, :y => 190,  :z => 241)
jump_gate system('Metrodora'),    system('Lycus'),     :location => Location.new(:x => 325,  :y => -403, :z => 140)
jump_gate system('Metrodora'),    system('Zenobia'),   :location => Location.new(:x => 193,  :y => -226, :z => -132)
jump_gate system('Lycus'),        system('Epaphras'),  :location => Location.new(:x => 301,  :y => 37,   :z => -449)
jump_gate system('Lycus'),        system('Isocrates'), :location => Location.new(:x => -8,   :y => 238,  :z => -179)
jump_gate system('Epaphras'),     system('Eugina'),    :location => Location.new(:x => 393,  :y => -29,  :z => -153)
jump_gate system('Eugina'),       system('Thais'),     :location => Location.new(:x => 476,  :y => -174, :z => -303)

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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 1000
      end
    }
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
      moon 'Anaye III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
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
                                                :eccentricity => 0.20, :semi_latus_rectum => 188,
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

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 750
      end
    }
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

jump_gate system('Loki'),     system('Heimdall'), :location => Location.new(:x => -464,  :y => 147,  :z => -162)
jump_gate system('Loki'),     system('Modi'),     :location => Location.new(:x => -480,  :y => 76,   :z => 380)
jump_gate system('Heimdall'), system('Nidhogg'),  :location => Location.new(:x => -376,  :y => -131, :z => 77)
jump_gate system('Modi'),     system('Nanna'),    :location => Location.new(:x => 175,   :y => 215,  :z => 94)
jump_gate system('Nanna'),    system('Fulla'),    :location => Location.new(:x => -225,  :y => -425, :z => 427)
jump_gate system('Fulla'),    system('Heimdall'), :location => Location.new(:x => 240,   :y => 484,  :z => 398)
jump_gate system('Fulla'),    system('Var'),      :location => Location.new(:x => -166,  :y => 51,   :z => 371)
jump_gate system('Nidhogg'),  system('Tyr'),      :location => Location.new(:x => 316,   :y => -459, :z => -4)
jump_gate system('Nidhogg'),  system('Ran'),      :location => Location.new(:x => -65,   :y => -13,  :z => 440)
jump_gate system('Tyr'),      system('Ran'),      :location => Location.new(:x => 35,    :y => 328,  :z => 2)
jump_gate system('Tyr'),      system('Loki'),     :location => Location.new(:x => 480,   :y => -73,  :z => -89)
jump_gate system('Ran'),      system('Var'),      :location => Location.new(:x => -338,  :y => 376,  :z => 133)
jump_gate system('Var'),      system('Ymi'),      :location => Location.new(:x => -82,   :y => -388, :z => -45)
jump_gate system('Var'),      system('Ran'),      :location => Location.new(:x => 112,   :y => 100,  :z => 132)
jump_gate system('Ymi'),      system('Nanna'),    :location => Location.new(:x => 436,   :y => -191, :z => -482)
jump_gate system('Ymi'),      system('Modi'),     :location => Location.new(:x => 106,   :y => 389,  :z => 149)

galaxy 'Odin' do |g|
  system 'Asgrad', 'FE8331', :location => Location.new(:x => 253, :y => -753, :z => -112) do |sys|
    planet 'Guguyni',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.32, :semi_latus_rectum => 193,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Guguyni I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Guguyni II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Haokah',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.63, :semi_latus_rectum => 191,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Hemaskas',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.78, :semi_latus_rectum => 136,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hemaskas I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hino',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.43, :semi_latus_rectum => 136,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hino I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hinu',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.82, :semi_latus_rectum => 172,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Hinu I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hinu II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hinu III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ibofanga',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.21, :semi_latus_rectum => 150,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ibofanga I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Valhalla', 'FE9782', :location => Location.new(:x => -10, :y => -523, :z => -492) do |sys|
    planet 'Ictinike',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.77, :semi_latus_rectum => 146,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Ictinike',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.92, :semi_latus_rectum => 116,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ictinike I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ictinike II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ictinike III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Igaluk',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.49, :semi_latus_rectum => 116,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Igaluk I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Igaluk II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Igaluk III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Igaluk IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ikto',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.3, :semi_latus_rectum => 148,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ikto I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ikto II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Iktomi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.55, :semi_latus_rectum => 192,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Iktomi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ioi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.17, :semi_latus_rectum => 107,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ioi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ioi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ioi III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ioskeha',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.87, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ioskeha I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ioskeha II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 1750
      end
    }
  end

  system 'Hel', 'FE7334', :location => Location.new(:x => 57, :y => 115, :z => 432) do |sys|
    planet 'Isitoq',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.80, :semi_latus_rectum => 101,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Isitoq I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Iya',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.27, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Iya I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Iya II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kaiti',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.4, :semi_latus_rectum => 116,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Kanati',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 199,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Karwan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.52, :semi_latus_rectum => 166,
                                                :direction => Motel.random_axis) do |pl|
    end

  end

  system 'Runic', 'FE7AA1', :location => Location.new(:x => 785, :y => 899, :z => 845) do |sys|
    planet 'Kioskurber',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.64, :semi_latus_rectum => 121,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Kivati',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.84, :semi_latus_rectum => 145,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Koko',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.89, :semi_latus_rectum => 187,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Koko I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Koyemsi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.97, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Koyemsi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Koyemsi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kumush',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.3, :semi_latus_rectum => 124,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kumush I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kwatee',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.75, :semi_latus_rectum => 140,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Kwatyat',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.63, :semi_latus_rectum => 144,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kwatyat I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kwatyat II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Logobola',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.66, :semi_latus_rectum => 111,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Logobola I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Logobola II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Logobola III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 1000
      end
    }
  end

  system 'Saga', 'FE7AA2', :location => Location.new(:x => -822, :y => 910, :z => -734) do |sys|
    planet 'Maheo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 120,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Maheo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Maheo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Malsum',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.4, :semi_latus_rectum => 157,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Malsum I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Malsun',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 117,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Mana',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.77, :semi_latus_rectum => 116,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Mana I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mana II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Jord', 'FE7AA3', :location => Location.new(:x => -999, :y => 456, :z => 650) do |sys|
    planet 'Manabozo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 102,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Manabush',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.94, :semi_latus_rectum => 180,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Manabush I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Manabush II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Manetto',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.64, :semi_latus_rectum => 187,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Manisar',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.84, :semi_latus_rectum => 178,
                                                :direction => Motel.random_axis) do |pl|
    end

  end

  system 'Norn', 'FE7AA4', :location => Location.new(:x => 921, :y => 880, :z => -820) do |sys|
    planet 'Manit',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.56, :semi_latus_rectum => 174,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Michabo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.52, :semi_latus_rectum => 145,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Michabo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Michabo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Mising',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 150,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Mising I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mising II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mising III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Moar',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 146,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Momo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.61, :semi_latus_rectum => 104,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Momo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Momo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet "Na'pi",
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.4, :semi_latus_rectum => 147,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Nanook',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.32, :semi_latus_rectum => 150,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nanook I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nanook II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nanook III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nanook IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nanook V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Napi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.4, :semi_latus_rectum => 124,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Napi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Napi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Napi III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Napi IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Nataska',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.7, :semi_latus_rectum => 108,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nataska I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nataska II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nataska III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nataska IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nataska V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nataska VI',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nataska VII',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Nerivik',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.83, :semi_latus_rectum => 191,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nerivik I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nerivik II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nerivik III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Nocoma',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.70, :semi_latus_rectum => 183,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nocoma I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nocoma II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nocoma III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Nocoma IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Nukatem',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.73, :semi_latus_rectum => 184,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nukatem I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Ogres', 'FE7AA5', :location => Location.new(:x => 888, :y => -777, :z => -666) do |sys|
    planet 'Nunuso',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.7, :semi_latus_rectum => 105,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nunuso I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ocasta',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.8, :semi_latus_rectum => 157,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ocasta I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Olelbis',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.18, :semi_latus_rectum => 170,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Onatah',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.12, :semi_latus_rectum => 132,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Onatah I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Owiot',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.74, :semi_latus_rectum => 195,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Pah',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.63, :semi_latus_rectum => 194,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Pah I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Pah II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Ulle', 'FE7AA6', :location => Location.new(:x => 807, :y => -749, :z => 850) do |sys|
    planet 'Palhik Mana',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.76, :semi_latus_rectum => 192,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Pamit',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.47, :semi_latus_rectum => 113,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Pamit I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Poia',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.46, :semi_latus_rectum => 106,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Qamaits',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.77, :semi_latus_rectum => 144,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Qamaits I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Qamaits II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Qamaits III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Quaayayp',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.55, :semi_latus_rectum => 105,
                                                :direction => Motel.random_axis) do |pl|
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 2000
      end
    }
  end

  system 'Njord', 'FE7AA7', :location => Location.new(:x => 909, :y => 808, :z => -853) do |sys|
    planet 'Raven',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.14, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Rhpisunt',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.26, :semi_latus_rectum => 163,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Rhpisunt I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Rhpisunt II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Sanopi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.62, :semi_latus_rectum => 109,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Sanopi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Sanopi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Sedna',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.49, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Sedna I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Sedna II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Sedna III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Syn', 'FE7AA8', :location => Location.new(:x => -935, :y => -942, :z => -908) do |sys|
    planet 'Selu',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 128,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Senx',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.81, :semi_latus_rectum => 105,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Shakaru',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.73, :semi_latus_rectum => 129,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Shakaru I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Sint Holo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.16, :semi_latus_rectum => 159,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Sint Holo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Sisiutl',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.84, :semi_latus_rectum => 169,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Skan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 109,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Skan I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Skan II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Skadi', 'FE7AA9', :location => Location.new(:x => 993, :y => 922, :z => -807) do |sys|
    planet 'Skili',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.69, :semi_latus_rectum => 100,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Skili I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Snoqalm',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.75, :semi_latus_rectum => 104,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Snoqalm I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Sotuknang',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.66, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Szeukha',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.50, :semi_latus_rectum => 110,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Szeukha I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Tabaldak',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.70, :semi_latus_rectum => 176,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tabaldak I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Tabaldak II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Taiowa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.26, :semi_latus_rectum => 147,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Taiowa I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Tamit',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.41, :semi_latus_rectum => 186,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tamit I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Tamit II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Tawiskara',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.11, :semi_latus_rectum => 114,
                                                :direction => Motel.random_axis) do |pl|
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 250
      end
    }
  end

  system 'Surtr', 'FE7AAC', :location => Location.new(:x => 974, :y => -973, :z => 775) do |sys|
    planet 'Theelgeth',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.67, :semi_latus_rectum => 152,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Theelgeth I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Tihtipihin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.34, :semi_latus_rectum => 147,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tihtipihin I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Tirawa',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.2, :semi_latus_rectum => 101,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Tolmalok',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.91, :semi_latus_rectum => 171,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Tonenili',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.54, :semi_latus_rectum => 146,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Tonenili I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

  end

  system 'Woden', 'FE7AAD', :location => Location.new(:x => 721, :y => 792, :z => -856) do |sys|
    planet 'Torngasak',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 142,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Torngasak I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Torngasak II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Tsohanoai',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.31, :semi_latus_rectum => 148,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Tukupar Itar',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.96, :semi_latus_rectum => 137,
                                                :direction => Motel.random_axis) do |pl|
    end

  end

  system 'Hermoda', 'FE7AAE', :location => Location.new(:x => -978, :y => -898, :z => -859) do |sys|
    planet 'Txamsem',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.21, :semi_latus_rectum => 194,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Uncegila',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.29, :semi_latus_rectum => 190,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Uncegila I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Uncegila II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Uncegila III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Unelanuki',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.59, :semi_latus_rectum => 195,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Unelanuki I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Unelanuki II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Unktome',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.70, :semi_latus_rectum => 127,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Utset',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.85, :semi_latus_rectum => 185,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Utset I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Utset II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Utset III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Utset IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Wabasso',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.47, :semi_latus_rectum => 107,
                                                :direction => Motel.random_axis) do |pl|
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 750
      end
    }
  end

  system 'Hlin', 'FE7AAF', :location => Location.new(:x => -721, :y => 998, :z => 889) do |sys|
    planet 'Wakan Tanka',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.86, :semi_latus_rectum => 151,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Wakan Tanka I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Wakanda',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.27, :semi_latus_rectum => 126,
                                                :direction => Motel.random_axis) do |pl|
    end

    planet 'Wakonda',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.53, :semi_latus_rectum => 117,
                                                :direction => Motel.random_axis) do |pl|
    end

  end
end

jump_gate system('Asgrad'),   system('Valhalla'),  :location => Location.new(:x => 329,  :y => -115, :z => 135)
jump_gate system('Saga'),     system('Valhalla'),  :location => Location.new(:x => -418, :y => -361, :z => 180)
jump_gate system('Norn'),     system('Valhalla'),  :location => Location.new(:x => -92,  :y => -46,  :z => 258)
jump_gate system('Ulle'),     system('Valhalla'),  :location => Location.new(:x => 367,  :y => -443, :z => -352)
jump_gate system('Syn'),      system('Valhalla'),  :location => Location.new(:x => -368, :y => 421,  :z => 168)
jump_gate system('Surtr'),    system('Valhalla'),  :location => Location.new(:x => -121, :y => -70,  :z => 142)
jump_gate system('Woden'),    system('Valhalla'),  :location => Location.new(:x => -432, :y => -144, :z => -366)
jump_gate system('Hlin'),     system('Valhalla'),  :location => Location.new(:x => -233, :y => -48,  :z => 411)
jump_gate system('Hel'),      system('Valhalla'),  :location => Location.new(:x => -428, :y => -166, :z => 231)
jump_gate system('Valhalla'), system('Hel'),       :location => Location.new(:x => -491, :y => 213,  :z => 287)
jump_gate system('Runic'),    system('Hel'),       :location => Location.new(:x => 473,  :y => 9,    :z => -335)
jump_gate system('Jord'),     system('Hel'),       :location => Location.new(:x => -496, :y => 17,   :z => 395)
jump_gate system('Ogres'),    system('Hel'),       :location => Location.new(:x => -468, :y => -312, :z => 210)
jump_gate system('Njord'),    system('Hel'),       :location => Location.new(:x => 47,   :y => 225,  :z => -346)
jump_gate system('Skadi'),    system('Hel'),       :location => Location.new(:x => 147,  :y => -242, :z => -93)
jump_gate system('Hermoda'),  system('Hel'),       :location => Location.new(:x => 362,  :y => 33,   :z => -388)

jump_gate system('Hel'),      system('Njord'),  :location => Location.new(:x => 387,     :y => -83,  :z => 33)
jump_gate system('Valhalla'), system('Asgrad'), :location => Location.new(:x => 157,     :y => 351,  :z => -110)

jump_gate system('Njord'),    system('Skadi'),      :location => Location.new(:x => 14,    :y => -448, :z => -70)
jump_gate system('Njord'),    system('Jord'),       :location => Location.new(:x => 190,   :y => 44,   :z => 383)
jump_gate system('Jord'),     system('Ogres'),      :location => Location.new(:x => -452,  :y => 482,  :z => 272)
jump_gate system('Jord'),     system('Runic'),      :location => Location.new(:x => 481,   :y => -175, :z => -322)
jump_gate system('Jord'),     system('Hermoda'),    :location => Location.new(:x => 336,   :y => -448, :z => 387)
jump_gate system('Hermoda'),  system('Ogres'),      :location => Location.new(:x => 498,   :y => -482, :z => 53)
jump_gate system('Runic'),    system('Ogres'),      :location => Location.new(:x => 58,    :y => 251,  :z => 209)

jump_gate system('Asgrad'),  system('Saga'),       :location => Location.new(:x => -254, :y => 263,  :z => 250)
jump_gate system('Asgrad'),  system('Norn'),       :location => Location.new(:x => 492,  :y => 438,  :z => -22)
jump_gate system('Asgrad'),  system('Woden'),      :location => Location.new(:x => 311,  :y => 279,  :z => 119)
jump_gate system('Asgrad'),  system('Hlin'),       :location => Location.new(:x => -489, :y => -274, :z => -335)
jump_gate system('Woden'),   system('Ulle'),       :location => Location.new(:x => 248,  :y => 37,   :z => 60)
jump_gate system('Woden'),   system('Syn'),        :location => Location.new(:x => -209, :y => -157, :z => 412)
jump_gate system('Hlin'),    system('Surtr'),      :location => Location.new(:x => -431, :y => -271, :z => 160)

galaxy 'Freya' do |g|
  system 'Fenrir', 'AA5521', :location => Location.new(:x => -323, :y => -360, :z => 369) do |sys|
    planet 'Gerd',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.45, :semi_latus_rectum => 180,
                                                :direction => Motel.random_axis)

    planet 'Waukheon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.51, :semi_latus_rectum => 199,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Waukheon I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Wendego',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.30, :semi_latus_rectum => 198,
                                                :direction => Motel.random_axis)

    planet 'Wetiko',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.61, :semi_latus_rectum => 171,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Wetiko I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Weywot',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.41, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis)

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Vithar', 'BA4429', :location => Location.new(:x => -853, :y => 853, :z => 346) do |sys|
    planet 'Winabozho',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.48, :semi_latus_rectum => 158,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Winabozho I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Winabozho II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Wisaaka',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.29, :semi_latus_rectum => 193,
                                                :direction => Motel.random_axis)

    planet 'Wonomi',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.4, :semi_latus_rectum => 174,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Wonomi I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Wonomi II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Wonomi III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Xelas',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.78, :semi_latus_rectum => 173,
                                                :direction => Motel.random_axis)
  end

  system 'Eir', 'ED0313', :location => Location.new(:x => -123, :y => 587, :z => 580) do |sys|
    planet 'Ah Puch',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.18, :semi_latus_rectum => 144,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ah Puch I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ahmakiq',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.37, :semi_latus_rectum => 117,
                                                :direction => Motel.random_axis)

    planet 'Akhushtal',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.55, :semi_latus_rectum => 147,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Akhushtal I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Akhushtal II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Bacabs',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.75, :semi_latus_rectum => 164,
                                                :direction => Motel.random_axis)

    planet 'Centeotl',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.95, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Centeotl I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Centeotl II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Chantico',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.48, :semi_latus_rectum => 169,
                                                :direction => Motel.random_axis)

    planet 'Ehecatl',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.41, :semi_latus_rectum => 161,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ehecatl I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ehecatl II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ehecatl III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ehecatl IV',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ehecatl V',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ekahau',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.76, :semi_latus_rectum => 176,
                                                :direction => Motel.random_axis)
  end

  system 'Garm', 'AA3041', :location => Location.new(:x => 100, :y => 750, :z => 582) do |sys|
    planet 'Ix Chel',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.92, :semi_latus_rectum => 177,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Ix Chel I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Ix Chel II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ixtab',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.61, :semi_latus_rectum => 161,
                                                :direction => Motel.random_axis)

    planet 'Kan-u-Uayeyab',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.9, :semi_latus_rectum => 131,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kan-u-Uayeyab I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kan-u-Uayeyab II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kan-u-Uayeyab III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kinich Kakmo',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.38, :semi_latus_rectum => 177,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kinich Kakmo I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Kinich Kakmo II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Kisin',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.60, :semi_latus_rectum => 139,
                                                :direction => Motel.random_axis)

    planet 'Kukucan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.26, :semi_latus_rectum => 108,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Kukucan I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Vili', 'DC5929', :location => Location.new(:x => 820, :y => -351, :z => 922) do |sys|
    planet 'Macuilxochitl',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.1, :semi_latus_rectum => 114,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Macuilxochitl I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Macuilxochitl II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Mayahuel',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.21, :semi_latus_rectum => 114,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Mayahuel I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mayahuel II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mayahuel III',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Mictlan',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.44, :semi_latus_rectum => 108,
                                                :direction => Motel.random_axis)

    planet 'Mitnal',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.34, :semi_latus_rectum => 177,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Mitnal I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Mitnal II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 750
      end
    }
  end

  system 'Gunlad', 'FF2002', :location => Location.new(:x => 220, :y => 773, :z => -667) do |sys|
    planet 'Nacon',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.66, :semi_latus_rectum => 181,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Nacon I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Ometecuhtli',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.21, :semi_latus_rectum => 195,
                                                :direction => Motel.random_axis)
  end

  system 'Edda', 'FF3003', :location => Location.new(:x => -515, :y => -623, :z => -112) do |sys|
    planet 'Paynal',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.19, :semi_latus_rectum => 148,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Paynal I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Quetzalcoatl',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.35, :semi_latus_rectum => 124,
                                                :direction => Motel.random_axis) do |pl|
      moon 'Quetzalcoatl I',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Quetzalcoatl II',   :location => rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Yaxche',
           :movement_strategy => Elliptical.new(:relative_to => Elliptical::RELATIVE_TO_FOCI, :speed => 0.1,
                                                :eccentricity => 0.33, :semi_latus_rectum => 135,
                                                :direction => Motel.random_axis)
    0.upto(50){
      asteroid gen_uuid, :location => rand_location(:min => 250, :max => 500) do |ast|
        resource :resource => rand_resource, :quantity => 1000
      end
    }
  end
end

jump_gate system('Fenrir'), system('Garm'),      :location => Location.new(:x => -427,  :y => 116,  :z => 474)
jump_gate system('Vithar'), system('Garm'),      :location => Location.new(:x => -415,  :y => 126,  :z => -209)
jump_gate system('Eir'),    system('Garm'),      :location => Location.new(:x => 264,  :y => 290,  :z => -262)
jump_gate system('Vili'),   system('Garm'),      :location => Location.new(:x => 165,  :y => -387,  :z => -148)
jump_gate system('Gunlad'), system('Garm'),      :location => Location.new(:x => 33,  :y => 449,  :z => -7)
jump_gate system('Edda'),   system('Garm'),      :location => Location.new(:x => -194,  :y => 38,  :z => 209)

jump_gate system('Garm'),   system('Fenrir'),    :location => Location.new(:x => -93,  :y => -30,  :z => -294)
jump_gate system('Garm'),   system('Vithar'),    :location => Location.new(:x => 83,  :y => 260,  :z => -309)
jump_gate system('Garm'),   system('Eir'),       :location => Location.new(:x => 456,  :y => 455,  :z => -43)
jump_gate system('Garm'),   system('Vili'),      :location => Location.new(:x => 80,  :y => -433,  :z => 78)
jump_gate system('Garm'),   system('Gunlad'),    :location => Location.new(:x => -140,  :y => 367,  :z => -319)
jump_gate system('Garm'),   system('Edda'),      :location => Location.new(:x => 23,  :y => -11,  :z => -121)

jump_gate system('Vili'),   system('Edda'),      :location => Location.new(:x => -34,  :y => 495,  :z => 68)
jump_gate system('Edda'),   system('Eir'),       :location => Location.new(:x => -95,  :y => 130,  :z => -226)
jump_gate system('Edda'),   system('Gunlad'),    :location => Location.new(:x => 272,  :y => -21,  :z => 433)
jump_gate system('Edda'),   system('Fenrir'),    :location => Location.new(:x => -322, :y => 8,    :z => 140)
jump_gate system('Edda'),   system('Vithar'),    :location => Location.new(:x => 341,  :y => 281,  :z => 445)
jump_gate system('Vithar'), system('Eir'),       :location => Location.new(:x => 59,   :y => -301, :z => 472)
jump_gate system('Vithar'), system('Gunlad'),    :location => Location.new(:x => 17,   :y => -163, :z => -142)
jump_gate system('Vithar'), system('Vili'),      :location => Location.new(:x => 177,  :y => 379,  :z => 430)
jump_gate system('Eir'),    system('Vili'),      :location => Location.new(:x => -473, :y => 20,   :z => 173)
