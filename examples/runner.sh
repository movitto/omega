#!/usr/bin/bash
# Create test data and run bots
#
# Copyright (C) 2012-2013-2013 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="$CURR_DIR/../.."

# create the universe
RUBYLIB='lib' ./examples/universes/small.rb

# create users
RUBYLIB='lib' ./examples/users.rb Anubis sibuna Athena regular_user

# run bots
RUBYLIB='lib' ./examples/bot.rb Anubis sibuna
