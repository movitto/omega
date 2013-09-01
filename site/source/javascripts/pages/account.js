/* accounts page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/containers"
//= require "omega"

// XXX temp hack, entities currently require base
// canvas ui definitions, need to fix this so this
// does not have to be included here
//= require "ui/canvas"

// initialize the page
$(document).ready(function(){ 
  // initialize node
  var node = new Node();
  node.on_error(function(e){
    // log all errors to the console
    console.log(e);
  });

  // initialize ui
  var account_info = new AccountInfoContainer();
  var ui = {account_info : account_info}
  wire_up_ui(ui, node);

  // restore session
  restore_session(ui, node);
});
