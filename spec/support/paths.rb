# Omega Spec Path Helpers
#
# Copyright (C) 2010-2014 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt

def spec_support_dir
  @spec_support_dir ||= File.expand_path(File.dirname(__FILE__))
end

def spec_dir
  @spec_dir ||= File.expand_path(File.join(spec_support_dir, '..'))
end

def lib_dir
  @lib_dir ||= File.expand_path(File.join(spec_dir, '..'))
end
