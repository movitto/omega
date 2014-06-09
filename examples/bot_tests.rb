# Hooks into bin/util/omega-monitor to
# run a variety of tests on client side entities
#
# Copyright (C) 2012-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

def test_miner(miner)
  success = false
  msg     = "not mining or moving"
  if miner.mining
    success = true
    msg     = "mining"
  elsif miner.location.movement_strategy.is_a?(Motel::MovementStrategies::Linear)
    success = true
    msg     = "moving"
  end

  {:success => success, :entity => miner, :message => msg}
end

def test_corvette(corvette)
  success = false
  msg     = "not attacking or moving"

  if corvette.location.movement_strategy.is_a?(Motel::MovementStrategies::Linear)
    success = true
    msg     = "moving"
  #elsif corvette.attacking? # TODO how to detect?
  #  success = true
  #  msg     = "mining"
  end

  {:success => success, :entity => corvette, :message => msg}
end

def test_factory(factory)
  # TODO test pick_system as well
  success = false
  msg     = "not constructing"
  # TODO devise better way to test
  if factory.cargo_quantity < Manufactured::Station.construction_cost(nil) &&
     factory.cargo_quantity < Manufactured::Ship.construction_cost(nil)
    success = "true"
    msg     = "constructing"
  end

  {:success => success, :entity => factory, :message => msg}
end

def run_tests(data)
  miners    = data.users.collect { |u| u.ships.select { |s| s.type == :mining   } }.flatten
  corvettes = data.users.collect { |u| u.ships.select { |s| s.type == :corvette } }.flatten
  factories = data.users.collect { |u| u.stations.select { |s| s.type == :manufacturing } }.flatten

  miners.collect    { |m| test_miner(m)    } +
  corvettes.collect { |c| test_corvette(c) } +
  factories.collect { |f| test_factory(f)  }
end
