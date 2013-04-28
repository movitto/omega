/* index page
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

    // show login & registration errors in an alert box
    if(error_msg['error']['class'] == 'Omega::DataNotFound' &&
       error_msg['error']['message'].slice(0,4) == "user")
         alert(error_msg['error']['message']);

    else if(error_msg['error']['class'] == 'ArgumentError' &&
            error_msg['error']['message'] == "invalid user")
         alert("invalid user credentials");
  });

  // setup interface and restore session
  wire_up_ui(ui, node);
  restore_session(ui, node);
});
