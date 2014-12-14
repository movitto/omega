# Towards Movement Strategy integration tests
#
# Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
# See COPYING for the License of this software

require 'spec_helper'
require 'motel/movement_strategies/towards'

module Motel::MovementStrategies
describe Towards do
  let(:towards) { Towards.new      }
  let(:loc)     { build(:location) }
  let(:tracked) { build(:location) }
end # describe Towards
end # module Motel::MovementStrategies
