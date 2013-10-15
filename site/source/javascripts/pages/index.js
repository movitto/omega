/* index page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/containers"
//= require "omega"

// initialize the page
$(document).ready(function(){ 
  // initialize node
  var node                 = new Node();
  node.on_error(function(e){
    // log all errors to the console
    console.log(e);

    // show login & registration errors in an alert box
    if(e['error']['class'] == 'Omega::DataNotFound')
       // && e['error']['message'].slice(0,4) == "user")
         alert(e['error']['message']);

    else if(e['error']['class'] == 'ArgumentError' &&
            e['error']['message'] == "invalid user")
         alert("invalid user credentials");
  });

  // initialize ui
  var nav_container       = new NavContainer();
  var status_indicator    = new StatusIndicator();
  var canvas_container    = new CanvasContainer();
  var dialog              = new Dialog();
  var ui = {nav_container    : nav_container,
            status_indicator : status_indicator,
            canvas_container : canvas_container,
            dialog           : dialog };
  wire_up_ui(ui, node);
                   
  // show the canvas by default on the index page
  ui.canvas_container.canvas.show();
  ui.canvas_container.canvas.lock(['top', 'left']);

  // restore session
  restore_session(ui, node);
});
