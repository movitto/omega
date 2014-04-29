#!/usr/bin/ruby
# Medium sized universe
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt


require 'omega/client/boilerplate'

login 'admin',  'nimda'

########################## define some helpers to gen data for this universe

def moon_locs(pl)
  {:min => pl.size * 1.5, :max => pl.size * 2.3}
end

def moon_loc(pl)
  rand_loc(:min => pl.size * 1.5, :max => pl.size * 2.3)
end

######################### universe itself

galaxy 'Zeus' do |g|
  athena = system 'Athena', 'HR1925' do |sys|

    planet 'Posseidon', :ms => planet_orbit do |pl|
      moons ['Posseidon I',   'Posseidon II',
             'Posseidon III', 'Posseidon IV'], :locations => moon_locs(pl)
    end

    planet 'Hermes', :ms => planet_orbit

    planet 'Apollo', :ms => planet_orbit do |pl|
      moons ['Apollo V', 'Apollo VII'], :locations => moon_locs(pl)
    end

    planet 'Hades', :ms => planet_orbit do |pl|
      moons ['Hades III',  'Hades IV',  'Hades V',
             'Hades VI',   'Hades VII', 'Hades VIII',
             'Hades IX',   'Hades XI',  'Hades XII',
             'Hades XIII', 'Hades XIV', 'Hades XV'], :locations => moon_locs(pl)
    end

    0.upto(15){
      asteroid gen_uuid do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  aphrodite = system 'Aphrodite', 'V866' do |sys|
    planet 'Xenon',     :ms => planet_orbit
    planet 'Aesop',     :ms => planet_orbit
    planet 'Cleopatra', :ms => planet_orbit
    planet 'Demon',     :ms => planet_orbit
    planet 'Lynos',     :ms => planet_orbit
    planet 'Heracules', :ms => planet_orbit

    0.upto(15){
      asteroid gen_uuid do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  theodosia = system 'Theodosia', 'ST9098' do |sys|
    planet 'Eukleides', :ms => planet_orbit
    planet 'Phoibe',    :ms => planet_orbit do |pl|
      moons ['Phiobe V', 'Phiobe VI'], :locations => moon_locs(pl)
    end

    planet 'Basilius', :ms => planet_orbit do |pl|
      moons ['Basilius V',    'Basilius VI', 'Basilius XII',
             'Basilius XIII', 'Basilius XV', 'Basilius XX',
             'Basilius XXI'],  :locations => moon_locs(pl)
    end

    planet 'Leonidas', :ms => planet_orbit do |pl|
      moon 'Leonidas V', :location => moon_loc(pl)
    end

    planet 'Pythagoras', :ms => planet_orbit do |pl|
      moons ['Pythagoras V', 'Pythagoras VI'], :locations => moon_locs(pl)
    end

    planet 'Zeno', :ms => planet_orbit do |pl|
      moons ['Zeno I', 'Zeno II', 'Zeno III'], :locations => moon_locs(pl)
    end

    planet 'Galene', :ms => planet_orbit
  end

  # for this system we specify specific orbits of planet / do not randomly gen
  nike = system 'Nike', 'QR1515' do |sys|
    [['Nike I',    {:e => 0.12,  :p => 1510, :speed => 0.039}],
     ['Nike II',   {:e => 0.94,  :p => 1436, :speed => 0.004}],
     ['Nike III',  {:e => 0.42,  :p => 1290, :speed => 0.009}],
     ['Nike IV',   {:e => 0.13,  :p => 1088, :speed => 0.033}],
     ['Nike V',    {:e => 0.291, :p => 1712, :speed => 0.009}],
     ['Nike VI',   {:e => 0.388, :p => 1174, :speed => 0.031}],
     ['Nike VII',  {:e => 0.77,  :p => 1100, :speed => 0.011}],
     ['Nike VIII', {:e => 0.22,  :p => 1500, :speed => 0.009}],
     ['Nike IX',   {:e => 0.32,  :p => 1508, :speed => 0.015}],
     ['Nike X',    {:e => 0.64,  :p => 1160, :speed => 0.046}]].each { |name, ms|
       ms.merge! :direction => random_axis(:orthogonal_to => orbital_plane)
       planet name, :ms => orbit(ms)
     }
  end

  philo = system 'Philo', 'HU1792' do |sys|
    planet 'Theophila', :ms => planet_orbit do |pl|
      moons ['Theophila X', 'Theophila XI',
             'Theophila XII'], :locations => moon_locs(pl)
    end

    planet 'Zosime', :ms => planet_orbit do |pl|
      moon 'Zosime I', :location => moon_loc(pl)
    end

    planet 'Xeno', :ms => planet_orbit do |pl|
      moons ['Xeno I', 'Xeno II'], :locations => moon_locs(pl)
    end

    0.upto(15){
      asteroid gen_uuid do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  aphroditus = system 'Aphroditus', 'V867' do |sys|
    planet 'Xenux', :ms => planet_orbit
    planet 'Aesou', :ms => planet_orbit
  end

  # another system which we specify specific planet orbits
  irene = system 'Irene', 'HZ1279' do |sys|
    [['Irene I',   {:e => 0.29, :p => 1280, :speed => 0.037}],
     ['Irene II',  {:e => 0.40, :p => 1038, :speed => 0.04 }],
     ['Korinna',   {:e => 0.71, :p => 1502, :speed => 0.033}],
     ['Gaiane',    {:e => 0.68, :p => 1367, :speed => 0.013}],
     ['Demetrius', {:e => 0.22, :p => 1078, :speed => 0.053}]].each { |name, ms|
       ms.merge! :direction => random_axis(:orthogonal_to => orbital_plane)
       planet name, :ms => orbit(ms)
     }
  end

  jump_gate athena,     aphrodite
  jump_gate athena,     philo
  jump_gate aphrodite,  athena
  jump_gate aphrodite,  philo
  jump_gate philo,      aphrodite
  jump_gate philo,      theodosia
  jump_gate theodosia,  philo
  jump_gate aphrodite,  nike
  jump_gate nike,       aphrodite
  jump_gate athena,     aphroditus
  jump_gate aphroditus, irene
  jump_gate irene,      theodosia
end


galaxy 'Hera' do |g|
  agathon = system 'Agathon', 'JJ7192' do |sys|
    planet 'Tychon', :ms => planet_orbit do |pl|
      moons ['Tychon I', 'Tychon II'], :locations => moon_locs(pl)
    end

    planet 'Pegasus', :ms => planet_orbit do |pl|
      moon 'Pegas', :location => moon_loc(pl)
    end

    planet 'Olympos', :ms => planet_orbit
    planet 'Zotikos', :ms => planet_orbit
    planet 'Zopyros', :ms => planet_orbit

    planet 'Kallisto', :ms => planet_orbit do |pl|
      moons ['Myrrine', 'Eugenia', 'Doris',
             'Draco',   'Dion',    'Elpis'],
             :locations => moon_locs(pl)
    end

    0.upto(15){
      asteroid gen_uuid do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  # another system which we specify specific planet orbits
  isocrates = system 'Isocrates', 'IL9091' do |sys|
    [['Isocrates I',   {:e => 0.42, :p => 1380, :speed => 0.063}],
     ['Isocrates II',  {:e => 0.42, :p => 1338, :speed => 0.051}],
     ['Isocrates III', {:e => 0.42, :p => 1163, :speed => 0.033}]].each { |name, ms|
       ms.merge! :direction => random_axis(:orthogonal_to => orbital_plane)
       planet name, :ms => orbit(ms)
     }
  end

  thais = system 'Thais', 'QR1021' do |sys|
    planet 'Rhode', :ms => planet_orbit
  end

  timon = system 'Timon', 'FZ6675'
  zoe   = system 'Zoe',   'FR7751'
  myron = system 'Myron', 'RZ9901'

  lysander = system 'Lysander', 'V21' do |sys|
    planet 'Lysandra', :ms => planet_orbit do |pl|
      moons ['Lysandra I', 'Lysandra II'], :locations => moon_locs(pl)
    end

    planet 'Lysandrus', :ms => planet_orbit do |pl|
      moon 'Lysandrus I', :location => moon_loc(pl)
    end

    planet 'Lysandrene', :ms => planet_orbit do |pl|
      moon 'Lysandrene I', :location => moon_loc(pl)
    end
  end

  pelagia = system 'Pelagia', 'HR1001' do |sys|
    planet 'Iason',     :ms => planet_orbit
    planet 'Dionysius', :ms => planet_orbit
  end

  pericles = system 'Pericles', 'ST5309'
  sophia   = system 'Sophia',   'ST5310'
  theodora = system 'Theodora', 'ST5311'

  tycho = system 'Tycho', 'Q931' do |sys|
    planet 'Agape', :ms => planet_orbit do |pl|
      moons ['Agape I', 'Agape II'], :locations => moon_locs(pl)
    end

    planet 'Argyros', :ms => planet_orbit do |pl|
      moon 'Argyrosa I', :location => moon_loc(pl)
    end

    planet 'Argyrosus', :ms => planet_orbit

    planet 'Hero', :ms => planet_orbit do |pl|
      moons ['Hero I', 'Hero II',
             'Hero III', 'Hero IV'], :locations => moon_locs(pl)
    end
  end

  stephanos = system 'Stephanos', 'ST111'

  jump_gate agathon,   thais
  jump_gate thais,     timon
  jump_gate timon,     zoe
  jump_gate zoe,       myron
  jump_gate myron,     lysander
  jump_gate lysander,  pelagia
  jump_gate pelagia,   pericles
  jump_gate pericles,  sophia
  jump_gate sophia,    theodora
  jump_gate theodora,  tycho
  jump_gate tycho,     stephanos
  jump_gate stephanos, agathon
  jump_gate stephanos, isocrates
  jump_gate isocrates, stephanos
end
