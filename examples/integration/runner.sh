#!/usr/bin/bash
# run the integration suite
#
# Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
# Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt

CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN_DIR="$CURR_DIR/../.."

# run omega-server
#$BIN_DIR/omega-server

# create the universe
$CURR_DIR/universe.rb

# create two users
$CURR_DIR/users.rb Anubis sibuna Athena regular_user
$CURR_DIR/users.rb Osiris siriso Athena regular_user

# create bots
$CURR_DIR/bot2.rb Anubis sibuna
#$CURR_DIR/bot.rb Obsiris siriso
