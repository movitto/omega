#!/usr/bin/ruby
# Medium sized universe
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/boilerplate'

login 'admin',  'nimda'

########################## define some helpers to gen data for this universe

def sys_loc
  rand_loc :min => 1000, :max => 2250, :min_y => 0, :max_y => 50
end

def ast_loc
   rand_loc(:max => 5000, :min => 2500, :min_y => 0, :max_y => 50)
end

def jg_loc
  rand_loc(:min => 2000, :max => 3000)
end

def orbital_plane
  [0, 1, 0]
end

def planet_orbit
  rand_orbit :min_e => 0.2,   :max_e => 0.7,
             :min_p => 2500,  :max_p => 4500,
             :min_s => 0.002, :max_s => 0.007,
             :direction => random_axis(:orthogonal_to => orbital_plane)
end

def moon_locs(pl)
  {:min => pl.size * 1.5, :max => pl.size * 2.3}
end

def moon_loc(pl)
  rand_loc(:min => pl.size * 1.5, :max => pl.size * 2.3)
end

######################### universe itself

galaxy 'Zeus' do |g|
  athena = system 'Athena', 'HR1925', :location => sys_loc do |sys|

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
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  aphrodite = system 'Aphrodite', 'V866', :location => sys_loc do |sys|
    planet 'Xenon',     :ms => planet_orbit
    planet 'Aesop',     :ms => planet_orbit
    planet 'Cleopatra', :ms => planet_orbit
    planet 'Demon',     :ms => planet_orbit
    planet 'Lynos',     :ms => planet_orbit
    planet 'Heracules', :ms => planet_orbit

    0.upto(15){
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  theodosia = system 'Theodosia', 'ST9098', :location => sys_loc do |sys|
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
  nike = system 'Nike', 'QR1515', :location => sys_loc do |sys|
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

  philo = system 'Philo', 'HU1792', :location => sys_loc do |sys|
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
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  aphroditus = system 'Aphroditus', 'V867', :location => sys_loc do |sys|
    planet 'Xenux', :ms => planet_orbit
    planet 'Aesou', :ms => planet_orbit
  end

  # another system which we specify specific planet orbits
  irene = system 'Irene', 'HZ1279', :location => sys_loc do |sys|
    [['Irene I',   {:e => 0.29, :p => 1280, :speed => 0.037}],
     ['Irene II',  {:e => 0.40, :p => 1038, :speed => 0.04 }],
     ['Korinna',   {:e => 0.71, :p => 1502, :speed => 0.033}],
     ['Gaiane',    {:e => 0.68, :p => 1367, :speed => 0.013}],
     ['Demetrius', {:e => 0.22, :p => 1078, :speed => 0.053}]].each { |name, ms|
       ms.merge! :direction => random_axis(:orthogonal_to => orbital_plane)
       planet name, :ms => orbit(ms)
     }
  end

  jump_gate athena,     aphrodite,  :location => jg_loc
  jump_gate athena,     philo,      :location => jg_loc
  jump_gate aphrodite,  athena,     :location => jg_loc
  jump_gate aphrodite,  philo,      :location => jg_loc
  jump_gate philo,      aphrodite,  :location => jg_loc
  jump_gate philo,      theodosia,  :location => jg_loc
  jump_gate theodosia,  philo,      :location => jg_loc
  jump_gate aphrodite,  nike,       :location => jg_loc
  jump_gate nike,       aphrodite,  :location => jg_loc
  jump_gate athena,     aphroditus, :location => jg_loc
  jump_gate aphroditus, irene,      :location => jg_loc
  jump_gate irene,      theodosia,  :location => jg_loc
end


galaxy 'Hera' do |g|
  agathon = system 'Agathon', 'JJ7192', :location => sys_loc do |sys|
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
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  # another system which we specify specific planet orbits
  isocrates = system 'Isocrates', 'IL9091', :location => sys_loc do |sys|
    [['Isocrates I',   {:e => 0.42, :p => 1380, :speed => 0.063}],
     ['Isocrates II',  {:e => 0.42, :p => 1338, :speed => 0.051}],
     ['Isocrates III', {:e => 0.42, :p => 1163, :speed => 0.033}]].each { |name, ms|
       ms.merge! :direction => random_axis(:orthogonal_to => orbital_plane)
       planet name, :ms => orbit(ms)
     }
  end

  thais = system 'Thais', 'QR1021', :location => sys_loc do |sys|
    planet 'Rhode', :ms => planet_orbit
  end

  timon = system 'Timon', 'FZ6675', :location => sys_loc
  zoe   = system 'Zoe',   'FR7751', :location => sys_loc
  myron = system 'Myron', 'RZ9901', :location => sys_loc

  lysander = system 'Lysander', 'V21', :location => sys_loc do |sys|
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

  pelagia = system 'Pelagia', 'HR1001', :location => sys_loc do |sys|
    planet 'Iason',     :ms => planet_orbit
    planet 'Dionysius', :ms => planet_orbit
  end

  pericles = system 'Pericles', 'ST5309', :location => sys_loc
  sophia   = system 'Sophia',   'ST5310', :location => sys_loc
  theodora = system 'Theodora', 'ST5311', :location => sys_loc

  tycho = system 'Tycho', 'Q931', :location => sys_loc do |sys|
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

  stephanos = system 'Stephanos', 'ST111', :location => sys_loc

  jump_gate agathon,   thais,     :location => jg_loc
  jump_gate thais,     timon,     :location => jg_loc
  jump_gate timon,     zoe,       :location => jg_loc
  jump_gate zoe,       myron,     :location => jg_loc
  jump_gate myron,     lysander,  :location => jg_loc
  jump_gate lysander,  pelagia,   :location => jg_loc
  jump_gate pelagia,   pericles,  :location => jg_loc
  jump_gate pericles,  sophia,    :location => jg_loc
  jump_gate sophia,    theodora,  :location => jg_loc
  jump_gate theodora,  tycho,     :location => jg_loc
  jump_gate tycho,     stephanos, :location => jg_loc
  jump_gate stephanos, agathon,   :location => jg_loc
  jump_gate stephanos, isocrates, :location => jg_loc
  jump_gate isocrates, stephanos, :location => jg_loc
end
