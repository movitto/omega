#!/usr/bin/ruby
# single integration test user
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

require 'rubygems'
require 'omega'

include Omega::DSL

USER_NAME  = ARGV.shift
PASSWORD   = ARGV.shift
ROLENAMES   = *ARGV

RJR::Logger.log_level= ::Logger::INFO
login 'admin',  :password => 'nimda'

u = user USER_NAME, :password => PASSWORD do
  ROLENAMES.each { |rn|
    role rn.intern
  }
end

alliance USER_NAME + "-alliance", :members => [u]
