#!/usr/bin/ruby
require 'omega/client/boilerplate'

def station_loc
  # TODO set orbit movement strategy
  rand_loc :min => 1000, :max => 3000
end

def ship_loc
  rand_loc :min => 1000, :max => 3000
end

login 'admin', 'nimda'

names   = ['Anubis',   'Aten',     'Horus',   'Imhotep',     'Ptah']

systems = ['Hercules', 'Leo',      'Orion',   'Libra',       'Hydra', 'Cetus',
           'Dorado',   'Grus',     'Lepus',   'Canis Major', 'Ara',   'Aquila',
           'Aries',    'Scorpius', 'Cyngus',  'Kepler',      'Vela',  'Lyra',
           'Draco',    'Virgo',    'Pices'].shuffle

names.each do |uid|
  user uid, uid, :npc => true do
    role :regular_user
  end

  user_system = system(systems.shift)

  station "#{uid}-station1",
          :user_id      => uid,
          :type         => :manufacturing,
          :solar_system => user_system,
          :location     => station_loc

  ship "#{uid}-miner1",
       :user_id      => uid,
       :type         => :mining,
       :solar_system => user_system,
       :location     => ship_loc

  ship "#{uid}-miner2",
       :user_id      => uid,
       :type         => :mining,
       :solar_system => user_system,
       :location     => ship_loc
end
