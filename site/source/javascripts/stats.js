/* stats page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega"

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
function refresh_cycle(){
  for(var stati in $omega_config['stats']){
    var stat = $omega_config['stats'][stati];
    Statistic.with_id(stat[0], stat[1], refresh_stats);
  }
  setTimeout(refresh_cycle, 5000);
}

// initialize the page
$(document).ready(function(){ 
  // initialize top level components
  var ui   = UI();
  var node = Node();

  node.on_error(function(e){
    // log all errors to the console
    console.log(e);
  });

  // track stats
  $stats = {};

  // setup interface and restore session
  wire_up_ui(ui, node);
  restore_session(ui, node, refresh_cycle);
});
