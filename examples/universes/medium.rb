#!/usr/bin/ruby
# Medium sized universe
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# TODO replace random axis + rand locations

require 'rubygems'
require 'omega/client/dsl'
require 'rjr/nodes/amqp'
require 'motel/location'
require 'motel/movement_strategies/elliptical'

include Omega::Client::DSL

include Motel
include Motel::MovementStrategies

RJR::Logger.log_level= ::Logger::INFO

dsl.rjr_node =
  RJR::Nodes::AMQP.new(:node_id => 'seeder', :broker => 'localhost')

login 'admin',  'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => loc(240,-360,110) do |sys|
    planet 'Posseidon', :movement_strategy =>
        Elliptical.new(:relative_to => Elliptical::FOCI,
                       :e => 0.6, :p => 1000, :speed => 0.013,
                       :direction => Motel.random_axis) do |pl|

      moon 'Posseidon I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon III', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Posseidon IV',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hermes', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.3, :p => 1834, :speed => 0.064,
                     :direction => Motel.random_axis)

    planet 'Apollo', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.8, :p => 1929, :speed => 0.021,
                     :direction => Motel.random_axis) do |pl|
      moon 'Apollo V',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Apollo VII', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Hades', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.9, :p => 1440, :speed => 0.064,
                     :direction => Motel.random_axis) do |pl|
      moon 'Hades III',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades IV',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades V',    :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VI',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VII',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades VIII', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades IX',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XI',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XII',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XIII', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XIV',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hades XV',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location =>
        rand_location(:max => 10000,
                      :min_y => 0, :max_y => 50) do |ast|
          resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Aphrodite', 'V866', :location => loc(-420,119,90) do |sys|
    planet 'Xenon', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.8, :p => 1493, :speed => 0.011,
                     :direction => Motel.random_axis)
    planet 'Aesop', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.55, :p => 1296, :speed => 0.034,
                     :direction => Motel.random_axis)
    planet 'Cleopatra', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.42, :p => 1473, :speed => 0.022,
                     :direction => Motel.random_axis)

    planet 'Demon', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.16, :p => 1070, :speed => 0.006,
                     :direction => Motel.random_axis)
    planet 'Lynos', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.3125, :p => 1373, :speed => 0.065,
                     :direction => Motel.random_axis)
    planet 'Heracules', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.49, :p => 1305, :speed => 0.051,
                     :direction => Motel.random_axis)

    0.upto(50){
      asteroid gen_uuid, :location =>
        rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Theodosia', 'ST9098', :location => loc(412,-132,342) do |sys|
    planet 'Eukleides', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.21, :p => 1437, :speed => 0.036,
                     :direction => Motel.random_axis)

    planet 'Phoibe', :movement_strategy => 
           Elliptical.new(:relative_to => Elliptical::FOCI,
                          :e => 0.1, :p => 1529, :speed => 0.03,
                          :direction => Motel.random_axis) do |pl|
      moon 'Phiobe V',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Phiobe VI',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Basilius', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.45, :p => 1864, :speed => 0.067,
                     :direction => Motel.random_axis) do |pl|
      moon 'Basilius V',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius VI',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XII', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XIII',:location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XV',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XX',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Basilius XXI', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Leonidas', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.55, :p => 1689, :speed => 0.067,
                     :direction => Motel.random_axis) do |pl|
      moon 'Leonidas V', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Pythagoras', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.66, :p => 1071, :speed => 0.004,
                     :direction => Motel.random_axis) do |pl|
      moon 'Pythagoras V',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Pythagoras VI', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Zeno', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.15, :p => 1684, :speed => 0.006,
                     :direction => Motel.random_axis) do |pl|
      moon 'Zeno I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Zeno II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Zeno III', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Galene', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.62, :p => 1266, :speed => 0.022,
                     :direction => Motel.random_axis)
  end

  system 'Nike', 'QR1515', :location => loc(-222,333,413) do |sys|
    planet 'Nike I', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.12, :p => 1510, :speed => 0.039,
                     :direction => Motel.random_axis)
    planet 'Nike II', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.94, :p => 1436, :speed => 0.004,
                     :direction => Motel.random_axis)
    planet 'Nike III', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.42, :p => 1290, :speed => 0.009,
                     :direction => Motel.random_axis)
    planet 'Nike IV', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.13, :p => 1088, :speed => 0.033,
                     :direction => Motel.random_axis)
    planet 'Nike V', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.291, :p => 1712, :speed => 0.009,
                     :direction => Motel.random_axis)
    planet 'Nike VI', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.388, :p => 1174, :speed => 0.031,
                     :direction => Motel.random_axis)
    planet 'Nike VII', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.77, :p => 1100, :speed => 0.011,
                     :direction => Motel.random_axis)
    planet 'Nike VIII', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.22, :p => 1500, :speed => 0.009,
                     :direction => Motel.random_axis)
    planet 'Nike IX', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.32, :p => 1508, :speed => 0.015,
                     :direction => Motel.random_axis)
    planet 'Nike X', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.64, :p => 1160, :speed => 0.046,
                     :direction => Motel.random_axis)
  end

  system 'Philo', 'HU1792', :location => loc(-142,-338,409) do |sys|
    planet 'Theophila', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.88, :p => 1662, :speed => 0.057,
                     :direction => Motel.random_axis) do |pl|
      moon 'Theophila X',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Theophila XI',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Theophila XII', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Zosime', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.25, :p => 1203, :speed => 0.06,
                     :direction => Motel.random_axis) do |pl|
      moon 'Zosime I', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Xeno', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.16, :p => 1814, :speed => 0.055,
                     :direction => Motel.random_axis) do |pl|
      moon 'Xeno I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Xeno II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location =>
        rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }

  end

  system 'Aphroditus', 'V867', :location => loc(-420,119,90) do |sys|
    planet 'Xenux', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.8, :p => 1441, :speed => 0.025,
                     :direction => Motel.random_axis)
    planet 'Aesou', :movement_strategy => 
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.7, :p => 124, :speed => 0.009,
                     :direction => Motel.random_axis)
  end

  system 'Irene', 'HZ1279', :location => loc(110,423,-455) do |sys|
    planet 'Irene I', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.29, :p => 1280, :speed => 0.037,
                     :direction => Motel.random_axis)
    planet 'Irene II', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.40, :p => 1038, :speed => 0.04,
                     :direction => Motel.random_axis)
    planet 'Korinna', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.71, :p => 1502, :speed => 0.033,
                     :direction => Motel.random_axis)
    planet 'Gaiane', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.68, :p => 1367, :speed => 0.013,
                     :direction => Motel.random_axis)
    planet 'Demetrius', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.223, :p => 1078, :speed => 0.053,
                     :direction => Motel.random_axis)
  end
end

athena    = system('Athena')
aphrodite = system('Aphrodite')
philo     = system('Philo')

jump_gate athena,    aphrodite, :location => loc(-2050,-2050,-2050)
jump_gate athena,    philo,     :location => loc( 2050, 2050, 2050)
jump_gate aphrodite, athena,    :location => loc(-2050, 2050,-2050)
jump_gate aphrodite, philo,     :location => loc( 2050,-2050, 2050)
jump_gate philo,     aphrodite, :location => loc( 2050,-2050, 2050)

galaxy 'Hera' do |g|
  system 'Agathon', 'JJ7192', :location => loc(-88,219,499) do |sys|
    planet 'Tychon', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.33, :p => 1815, :speed => 0.022,
                     :direction => Motel.random_axis) do |pl|
      moon 'Tyhon I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Tyhon II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Pegasus', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.42, :p => 1458, :speed => 0.06,
                     :direction => Motel.random_axis) do |pl|
      moon 'Pegas',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Olympos', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.52, :p => 1413, :speed => 0.043,
                     :direction => Motel.random_axis)

    planet 'Zotikos', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.31, :p => 1037, :speed => 0.031,
                     :direction => Motel.random_axis)

    planet 'Zopyros', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.66, :p => 1968, :speed => 0.004,
                     :direction => Motel.random_axis)

    planet 'Kallisto', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.46, :p => 1519, :speed => 0.062,
                     :direction => Motel.random_axis) do |pl|
      moon 'Myrrine',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Eugenia',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Doris',     :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Draco',     :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Dion',      :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Elpis',     :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    0.upto(50){
      asteroid gen_uuid, :location =>
        rand_location(:min => 250, :max => 1000, :min_y => 0) do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Isocrates', 'IL9091', :location => loc(-104,-399,-438) do |sys|
    planet 'Isocrates I', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.42, :p => 1380, :speed => 0.063,
                     :direction => Motel.random_axis)

    planet 'Isocrates II', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.42, :p => 1338, :speed => 0.051,
                     :direction => Motel.random_axis)

    planet 'Isocrates III', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.42, :p => 1163, :speed => 0.033,
                     :direction => Motel.random_axis)
  end

  system 'Thais', 'QR1021', :location => loc(116,588,-91) do |sys|
    planet 'Rhode', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.5, :p => 1352, :speed => 0.026,
                     :direction => Motel.random_axis)
  end

  system 'Timon', 'FZ6675', :location => loc(88,268,91)
  system 'Zoe',   'FR7751', :location => loc(-81,-178,-381)
  system 'Myron', 'RZ9901', :location => loc(498,-114,101)

  system 'Lysander', 'V21', :location => loc(231,112,575) do |sys|
    planet 'Lysandra', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.46, :p => 1944, :speed => 0.065,
                     :direction => Motel.random_axis) do |pl|
      moon 'Lysandra I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Lysandra II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Lysandrus', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.49, :p => 1048, :speed => 0.032,
                     :direction => Motel.random_axis) do |pl|
      moon 'Lysandrus I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Lysandrene', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.66, :p => 1422, :speed => 0.021,
                     :direction => Motel.random_axis) do |pl|
      moon 'Lysandrene I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Pelagia', 'HR1001', :location => loc(-212,-321,466) do |sys|
    planet 'Iason', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.48, :p => 1962, :speed => 0.05,
                     :direction => Motel.random_axis)
    planet 'Dionysius', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.69, :p => 1125, :speed => 0.049,
                     :direction => Motel.random_axis)
  end

  system 'Pericles', 'ST5309', :location => loc(-156,-341,-177)
  system 'Sophia',   'ST5310', :location => loc(266,-255,-244)
  system 'Theodora', 'ST5311', :location => loc(500,118,326)

  system 'Tycho', 'Q931', :location => loc(420,-420,420) do |sys|
    planet 'Agape', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.16, :p => 1904, :speed => 0.05,
                     :direction => Motel.random_axis) do |pl|
      moon 'Agape I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Agape II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Argyros', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.16, :p => 1723, :speed => 0.035,
                     :direction => Motel.random_axis) do |pl|
      moon 'Argyrosa I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end

    planet 'Argyrosus', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.55, :p => 1522, :speed => 0.06,
                     :direction => Motel.random_axis)

    planet 'Hero', :movement_strategy =>
      Elliptical.new(:relative_to => Elliptical::FOCI,
                     :e => 0.33, :p => 1723, :speed => 0.039,
                     :direction => Motel.random_axis) do |pl|
      moon 'Hero I',   :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero II',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero III', :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
      moon 'Hero IV',  :location =>
        rand_location(:min => pl.size, :max => pl.size * 2.3)
    end
  end

  system 'Stephanos', 'ST111', :location => loc(51,-63,500)
end
