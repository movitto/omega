# include all user modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# Users subsytem - provides mechanisms to define and manipulates
# users, privileges, groups, sessions, etc
module Users ; end

lib = File.dirname(__FILE__)
$: << lib + '/users/'

require lib + '/users/common'
require lib + '/users/password_helper'
require lib + '/users/email_helper'
require lib + '/users/user'
require lib + '/users/alliance'
require lib + '/users/chat_proxy'
require lib + '/users/session'
require lib + '/users/privilege'
require lib + '/users/rjr_adapter'
require lib + '/users/registry'
