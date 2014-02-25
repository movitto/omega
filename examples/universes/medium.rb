#!/usr/bin/ruby
# Medium sized universe
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'omega/client/boilerplate'

login 'admin',  'nimda'

galaxy 'Zeus' do |g|
  system 'Athena', 'HR1925', :location => loc(240,-360,110) do |sys|
    orbital_plane = [0, 1, 0]

    planet 'Posseidon', :ms => orbit(:speed => 0.013, :e => 0.6, :p => 1000,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Posseidon I', 'Posseidon II', 'Posseidon III', 'Posseidon IV'],
            :locations => {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Hermes', :ms => orbit(:speed => 0.064, :e => 0.3, :p => 1834,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    planet 'Apollo', :ms => orbit(:speed => 0.021, :e => 0.8, :p => 1929,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Apollo V', 'Apollo VII'], :locations => 
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Hades', :ms => orbit(:e => 0.9, :p => 1440, :speed => 0.064,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Hades III',  'Hades IV',  'Hades V',
             'Hades VI',   'Hades VII', 'Hades VIII',
             'Hades IX',   'Hades XI',  'Hades XII',
             'Hades XIII', 'Hades XIV', 'Hades XV'],
            :locations => {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    0.upto(50){
      ast_loc = rand_loc(:max => 10000, :min_y => 0, :max_y => 50)
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Aphrodite', 'V866', :location => loc(-420,119,90) do |sys|
    orbital_plane = [0, 1, 0]

    planet 'Xenon', :ms => orbit(:e => 0.8, :p => 1493, :speed => 0.011,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    planet 'Aesop', :ms => orbit(:e => 0.55, :p => 1296, :speed => 0.034,
           :direction => random_axis(:orthogonal_to => orbital_plane))
    planet 'Cleopatra', :ms => orbit(:e => 0.42, :p => 1473, :speed => 0.022,
           :direction => random_axis(:orthogonal_to => orbital_plane))
    planet 'Demon', :ms => orbit(:e => 0.16, :p => 1070, :speed => 0.006,
           :direction => random_axis(:orthogonal_to => orbital_plane))
    planet 'Lynos', :ms => orbit(:e => 0.3125, :p => 1373, :speed => 0.065,
           :direction => random_axis(:orthogonal_to => orbital_plane))
    planet 'Heracules', :ms => orbit(:e => 0.49, :p => 1305, :speed => 0.051,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    0.upto(50){
      ast_loc = rand_loc(:min => 250, :max => 1000, :min_y => 0)
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Theodosia', 'ST9098', :location => loc(412,-132,342) do |sys|
    orbital_plane = [0, 1, 0]

    planet 'Eukleides', :ms => orbit(:e => 0.21, :p => 1437, :speed => 0.036,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    planet 'Phoibe', :ms => orbit(:e => 0.1, :p => 1529, :speed => 0.03,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Phiobe V', 'Phiobe VI'], :locations => 
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Basilius', :ms => orbit(:e => 0.45, :p => 1864, :speed => 0.067,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Basilius V',    'Basilius VI', 'Basilius XII',
             'Basilius XIII', 'Basilius XV', 'Basilius XX', 'Basilius XXI'],
            :locations => {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Leonidas', :ms => orbit(:e => 0.55, :p => 1689, :speed => 0.067,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moon 'Leonidas V', :location => rand_loc(:min => pl.size * 1.5,
                                               :max => pl.size * 2.3)
    end

    planet 'Pythagoras', :ms => orbit(:e => 0.66, :p => 1071, :speed => 0.004,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Pythagoras V', 'Pythagoras VI'], :locations =>
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Zeno', :ms => orbit(:e => 0.15, :p => 1684, :speed => 0.006,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Zeno I', 'Zeno II', 'Zeno III'], :locations =>
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Galene', :ms => orbit(:e => 0.62, :p => 1266, :speed => 0.022,
           :direction => random_axis(:orthogonal_to => orbital_plane))
  end

  system 'Nike', 'QR1515', :location => loc(-222,333,413) do |sys|
    orbital_plane = [0, 1, 0]

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
       planet name, :ms => orbit(ms.merge(:direction =>
              random_axis(:orthogonal_to => orbital_plane)))
     }
  end

  system 'Philo', 'HU1792', :location => loc(-142,-338,409) do |sys|
    orbital_plane = [0, 1, 0]

    planet 'Theophila', :ms => orbit(:e => 0.88, :p => 1662, :speed => 0.057,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Theophila X', 'Theophila XI', 'Theophila XII'],
            :locations => {:min => pl.size * 1.5, :max => pl.size * 2.3}
        
    end

    planet 'Zosime', :ms => orbit(:e => 0.25, :p => 1203, :speed => 0.06,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moon 'Zosime I', :location => rand_loc(:min => pl.size * 1.5,
                                             :max => pl.size * 2.3)
    end

    planet 'Xeno', :ms => orbit(:e => 0.16, :p => 1814, :speed => 0.055,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Xeno I', 'Xeno II'], :locations =>
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    0.upto(50){
      ast_loc = rand_loc(:min => 250, :max => 1000, :min_y => 0)
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Aphroditus', 'V867', :location => loc(-420,119,90) do |sys|
    orbital_plane = [0, 1, 0]
    planet 'Xenux', :ms => orbit(:e => 0.8, :p => 1441, :speed => 0.025,
           :direction => random_axis(:orthogonal_to => orbital_plane))
    planet 'Aesou', :ms => orbit(:e => 0.7, :p => 124, :speed => 0.009,
           :direction => random_axis(:orthogonal_to => orbital_plane))
  end

  system 'Irene', 'HZ1279', :location => loc(110,423,-455) do |sys|
    orbital_plane = [0, 1, 0]
    [['Irene I',   {:e => 0.29, :p => 1280, :speed => 0.037}],
     ['Irene II',  {:e => 0.40, :p => 1038, :speed => 0.04 }],
     ['Korinna',   {:e => 0.71, :p => 1502, :speed => 0.033}],
     ['Gaiane',    {:e => 0.68, :p => 1367, :speed => 0.013}],
     ['Demetrius', {:e => 0.22, :p => 1078, :speed => 0.053}]].each { |name, ms|
       planet name, :ms => orbit(ms.merge(:direction =>
              random_axis(:orthogonal_to => orbital_plane)))
     }
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
    orbital_plane = [0, 1, 0]
    planet 'Tychon', :ms => orbit(:e => 0.33, :p => 1815, :speed => 0.022,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Tychon I', 'Tychon II'], :locations =>
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Pegasus', :ms => orbit(:e => 0.42, :p => 1458, :speed => 0.06,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moon 'Pegas', :location =>
           rand_loc(:min => pl.size * 1.5, :max => pl.size * 2.3)
    end

    planet 'Olympos', :ms => orbit(:e => 0.52, :p => 1413, :speed => 0.043,
           :direction => random_axis(:orthogonal_to => orbital_plane))
                     

    planet 'Zotikos', :ms => orbit(:e => 0.31, :p => 1037, :speed => 0.031,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    planet 'Zopyros', :ms => orbit(:e => 0.66, :p => 1968, :speed => 0.004,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    planet 'Kallisto', :ms => orbit(:e => 0.46, :p => 1519, :speed => 0.062,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Myrrine', 'Eugenia', 'Doris', 'Draco', 'Dion', 'Elpis'],
            :locations => {:min => pl.size, :max => pl.size * 2.3}
    end

    0.upto(50){
      ast_loc = rand_location(:min => 250, :max => 1000, :min_y => 0)
      asteroid gen_uuid, :location => ast_loc do |ast|
        resource :resource => rand_resource, :quantity => 500
      end
    }
  end

  system 'Isocrates', 'IL9091', :location => loc(-104,-399,-438) do |sys|
    orbital_plane = [0, 1, 0]
    [['Isocrates I',   {:e => 0.42, :p => 1380, :speed => 0.063}],
     ['Isocrates II',  {:e => 0.42, :p => 1338, :speed => 0.051}],
     ['Isocrates III', {:e => 0.42, :p => 1163, :speed => 0.033}]].each { |name, ms|
       planet name, :ms => orbit(ms.merge({:direction =>
              random_axis(:orthogonal_to => orbital_plane)}))
     }
  end

  system 'Thais', 'QR1021', :location => loc(116,588,-91) do |sys|
    orbital_plane = [0, 1, 0]
    planet 'Rhode', :ms => orbit(:e => 0.5, :p => 1352, :speed => 0.026,
           :direction => random_axis(:orthogonal_to => orbital_plane))
  end

  system 'Timon', 'FZ6675', :location => loc(88,268,91)
  system 'Zoe',   'FR7751', :location => loc(-81,-178,-381)
  system 'Myron', 'RZ9901', :location => loc(498,-114,101)

  system 'Lysander', 'V21', :location => loc(231,112,575) do |sys|
    orbital_plane = [0, 1, 0]

    planet 'Lysandra', :ms => orbit(:e => 0.46, :p => 1944, :speed => 0.065,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Lysandra I', 'Lysandra II'], :locations =>
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Lysandrus', :ms => orbit(:e => 0.49, :p => 1048, :speed => 0.032,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moon 'Lysandrus I', :location =>
           rand_loc(:min => pl.size * 1.5, :max => pl.size * 2.3)
    end

    planet 'Lysandrene', :ms => orbit(:e => 0.66, :p => 1422, :speed => 0.021,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moon 'Lysandrene I', :location =>
           rand_loc(:min => pl.size * 1.5, :max => pl.size * 2.3)
    end
  end

  system 'Pelagia', 'HR1001', :location => loc(-212,-321,466) do |sys|
    orbital_plane = [0, 1, 0]
    planet 'Iason', :ms => orbit(:e => 0.48, :p => 1962, :speed => 0.05,
           :direction => random_axis(:orthogonal_to => orbital_plane))
    planet 'Dionysius', :ms => orbit(:e => 0.69, :p => 1125, :speed => 0.049,
           :direction => random_axis(:orthogonal_to => orbital_plane))
  end

  system 'Pericles', 'ST5309', :location => loc(-156,-341,-177)
  system 'Sophia',   'ST5310', :location => loc(266,-255,-244)
  system 'Theodora', 'ST5311', :location => loc(500,118,326)

  system 'Tycho', 'Q931', :location => loc(420,-420,420) do |sys|
    orbital_plane = [0, 1, 0]

    planet 'Agape', :ms => orbit(:e => 0.16, :p => 1904, :speed => 0.05,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Agape I', 'Agape II'], :locations =>
            {:min => pl.size * 1.5, :max => pl.size * 2.3}
    end

    planet 'Argyros', :ms => orbit(:e => 0.16, :p => 1723, :speed => 0.035,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moon 'Argyrosa I', :location =>
           rand_loc(:min => pl.size * 1.5, :max => pl.size * 2.3)
    end

    planet 'Argyrosus', :ms => orbit(:e => 0.55, :p => 1522, :speed => 0.06,
           :direction => random_axis(:orthogonal_to => orbital_plane))

    planet 'Hero', :ms => orbit(:e => 0.33, :p => 1723, :speed => 0.039,
           :direction => random_axis(:orthogonal_to => orbital_plane)) do |pl|
      moons ['Hero I', 'Hero II', 'Hero III', 'Hero IV'],
            :locations => {:min => pl.size, :max => pl.size * 2.3}
    end
  end

  system 'Stephanos', 'ST111', :location => loc(51,-63,500)
end
