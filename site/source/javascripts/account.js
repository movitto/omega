/* accounts page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega"

// initialize the page
$(document).ready(function(){ 
  // initialize top level components
  var ui   = UI();
  var node = Node();

  node.on_error(function(e){
    // log all errors to the console
    console.log(e);
  });

  // setup interface and restore session
  wire_up_ui(ui, node);
  restore_session(ui, node);
});
