# include all motel modules
#
# Copyright (C) 2009 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

lib = File.dirname(__FILE__)

require lib + '/motel/conf'
require lib + '/motel/runner'
require lib + '/motel/loader'
require lib + '/motel/simrpc'

Dir[lib + '/motel/models/*.rb'].each { |model| require model }
