# Omega Spec Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

################################################################ deps / env

# setup path to load omega
require 'support/paths'
$: << lib_dir

# require main omega components
require 'omega'

# include support modules
require 'support/attributes'
require 'support/client'
require 'support/cosmos_entity'
require 'support/dispatcher'
require 'support/movement_strategy'
require 'support/permissions'
require 'support/registry'
require 'support/server_entity'
require 'support/trackable'

# spec and factory girl configuration / setup
require 'support/factory_girl'
require 'support/rspec'

# some generic test constructs

UUID_PATTERN = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/

module OmegaTest
  CLOSE_ENOUGH=0.00001
  CLOSE_PRECISION=4
end
