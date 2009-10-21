# loads and runs all tests for the motel project
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

require 'test/unit'
require 'mocha'

require File.dirname(__FILE__) + '/../lib/motel'

include Motel
include Motel::Models

require 'test/location_test'
require 'test/movement_strategy_test'
require 'test/runner_test'
require 'test/loader_test'
require 'test/simrpc_test'
#Dir['**/*_test.rb'].each { |test_case| require test_case }
