/* stats page
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

// TODO move stats into its own reusable module (use here & on acct page)

require('javascripts/omega/config.js');
require('javascripts/omega/client.js');
require('javascripts/omega/user.js');
require('javascripts/omega/commands.js');

// log all errors to the console
function errors_to_console(error_msg){
  console.log(error_msg);
}

// repopulate the states panels w/ stats
function refresh_stats(stat_result){
  var sd = $('#stats ul');
  sd.html('');
  $stats[stat_result.stat_id] = stat_result;
  for(var stati in $stats){
    var stat = $stats[stati];
    sd.append('<li>' + stat.stat.description + ": " + stat.value + '</li>');
  }
}

// retrieve all stats, refresh ui, and
// schedule this again in 5s
function refresh_cycle(args){
  for(var stati in $omega_config['stats']){
    var stat = $omega_config['stats'][stati];
    OmegaQuery.stat(stat[0], stat[1], refresh_stats);
  }
  setTimeout(refresh_cycle, 5000);
}

// initialize the page
$(document).ready(function(){ 
  $stats          = {};
  $omega_node     = new OmegaClient();
  $omega_session  = new OmegaSession();
  OmegaCommand.init();

  $omega_node.add_error_handler(errors_to_console);
  $omega_session.on_session_validated(refresh_cycle);
});
