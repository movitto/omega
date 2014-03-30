#!/usr/bin/ruby
require 'omega/client/boilerplate'

login 'admin', 'nimda'

def system_loc
  # TODO more organized / algorithmic system positioning
  # (still w/ some random variance)
  rand_loc(:min => 1000, :max => 2500, :max_y => 250, :min_y => 0)
end

def system_asteroids
  e =  rand *  0.6 + 0.2
  p = (rand * 4500 + 2000).floor
  asteroid_belt :e => e, :p => p, :scale => 10,
                :direction => random_axis(:orthogonal_to => [0,1,0]) do
    @asteroids.each { |ast| asteroid_resources(ast) }
  end
end

def asteroid_resources(ast)
  resource :resource => rand_resource, :asteroid => ast, :quantity => 500
end

def system_planets
  num = (rand * 3 + 4).floor
  0.upto(num) do |i|
    e =  rand * 0.4 + 0.3
    p = (rand * 4000 + 1000).floor
    s =  rand * 0.03 + 0.001
    planet "#{@solar_system.name}#{i}", :movement_strategy =>
      orbit(:e => e, :p => p, :speed => s,
            :direction => random_axis(:orthogonal_to => [0,1,0]))
  end
end

def create_system(name)
  system name, "HD#{(rand*5000).floor}", :location => system_loc do
    system_asteroids
    system_planets
  end
end

galaxy 'Omega Centauri' do
  hercules = create_system 'Hercules'
  leo      = create_system 'Leo'
  orion    = create_system 'Orion'
  libra    = create_system 'Libra'
  hydra    = create_system 'Hydra'
  cetus    = create_system 'Cetus'
  dorado   = create_system 'Dorado'

  grus     = create_system 'Grus'
  lepus    = create_system 'Lepus'
  canis    = create_system 'Canis Major'
  ara      = create_system 'Ara'
  aquila   = create_system 'Aquila'
  aries    = create_system 'Aries'

  scorpius = create_system 'Scorpius'
  cyngus   = create_system 'Cyngus'
  kepler   = create_system 'Kepler'
  vela     = create_system 'Vela'
  lyra     = create_system 'Lyra'
  draco    = create_system 'Draco'
  virgo    = create_system 'Virgo'
  pices    = create_system 'Pices'

  # TODO set jump gate locations
  interconnect hercules, leo, orion, libra, hydra, cetus, dorado
  interconnect grus, lepus, canis, ara, aquila, aries
  interconnect scorpius, cyngus, kepler, vela, lyra, draco, virgo, pices

  interconnect hercules, grus, scorpius
end
