#!/usr/bin/bash
# run the integration suite
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="$CURR_DIR/../.."

# run omega-server
$BIN_DIR/omega-server

# create the universe
$CURR_DIR/universe.rb

# create two users
# FIXME create role w/ only required privs
$CURR_DIR/users.rb Anubis sibuna superadmin
$CURR_DIR/users.rb Ra ar superadmin

# create two bots
$CURR_DIR/bot.rb Anubis Athena
$CURR_DIR/bot.rb Ra Agathon
