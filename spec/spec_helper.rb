# Omega Spec Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

################################################################ deps / env

require 'support/paths'
$: << lib_dir

require 'omega'

require 'support/permissions'
require 'support/attributes'
require 'support/dispatcher'
require 'support/client'

require 'support/factory_girl'
require 'support/rspec'


UUID_PATTERN = /[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/

module OmegaTest
  CLOSE_ENOUGH=0.00001
end
