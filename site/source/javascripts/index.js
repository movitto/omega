/* index page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega"

// initialize the page
$(document).ready(function(){ 
  // initialize top level components
  var ui   = new UI();
  var node = new Node();

  node.on_error(function(e){
    // log all errors to the console
    console.log(e);

    // show login & registration errors in an alert box
    if(e['error']['class'] == 'Omega::DataNotFound' &&
       e['error']['message'].slice(0,4) == "user")
         alert(e['error']['message']);

    else if(e['error']['class'] == 'ArgumentError' &&
            e['error']['message'] == "invalid user")
         alert("invalid user credentials");
  });

  // setup interface and restore session
  wire_up_ui(ui, node);
  restore_session(ui, node);

  // show the canvas by default on the index page
  ui.canvas.show();
});
