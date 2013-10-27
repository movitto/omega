/* dev page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/containers"
//= require "omega"

function custom_operations(ui, node){
}

// initialize the page
$(document).ready(function(){ 
  // initialize node
  var node = new Node();
  node.on_error(function(e){
    // log all errors to the console
    console.log(e);
  });

  // setup interface
  var ui = {canvas_container    : new CanvasContainer(),
            effects_player      : new EffectsPlayer()};
  wire_up_ui(ui, node);

  // restore session
  restore_session(ui, node, function(res){
    custom_operations(ui, node);
  });
 
  // show the canvas by default
  ui.canvas_container.canvas.show();
});
