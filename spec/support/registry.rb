# Omega Spec Registry Helper
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

def registry_entity(registry, &matcher)
  registry.safe_exec { |entities| entities.find &matcher }
end
