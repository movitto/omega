# include all user modules
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

# Users subsytem - provides mechanisms to define and manipulates
# users, privileges, groups, sessions, etc
module Users ; end

require 'users/common'
require 'users/password_helper'
require 'users/email_helper'
require 'users/attribute'
require 'users/user'
require 'users/alliance'
require 'users/chat_proxy'
require 'users/session'
require 'users/privilege'
require 'users/role'
require 'users/rjr_adapter'
require 'users/registry'

require 'users/attributes/own'
require 'users/attributes/interact'
require 'users/attributes/pilot'
require 'users/attributes/construct'
require 'users/attributes/other'
