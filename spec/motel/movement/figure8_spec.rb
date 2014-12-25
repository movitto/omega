# Figure8 Movement Strategy integration tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/figure8'

module Motel::MovementStrategies
describe Figure8, :integration => true do
  let(:figure8) { Figure8.new      }
  let(:loc)     { build(:location) }
  let(:tracked) { build(:location) }
end # describe Figure8
end # module Motel::MovementStrategies
