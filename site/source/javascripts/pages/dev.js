/* dev page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/containers"
//= require "omega"

// do whatever you would like to here
var custom_operations = function(ui, node){
  ui.canvas_container.canvas.
     scene.skybox.background('galaxy1');
  ui.canvas_container.canvas.scene.
     add_component(ui.canvas_container.canvas.scene.skybox.components[0]);

  //var oor     = [0, -0.675463180551152, -0.7373937155412466];
  var oor     = [0,0,1];
  //var oor     = [0.61,0.61,0.52];
  var loc1    = new Location({ x : 0, y : 0, z : 0,
                              orientation_x : oor[0],
                              orientation_y : oor[1],
                              orientation_z : oor[2],
                              movement_strategy : { json_class : 'Motel::MovementStrategies::Linear' }})
  var ship1 = new Ship({id : 'ship1', location : loc1, hp : 50, type : 'corvette'});
  ui.canvas_container.canvas.scene.add_entity(ship1);

  ui.canvas_container.canvas.scene.camera.rotate(0, 3.14)
  ui.canvas_container.canvas.scene.camera.zoom(-760);
  ui.canvas_container.canvas.scene.animate();

  $.timer(function(){
    var new_or = rot(ship1.location.orientation_x,
                     ship1.location.orientation_y,
                     ship1.location.orientation_z, 0.1, 0.62, 0.62, 0.52)
    ship1.location.orientation_x = new_or[0];
    ship1.location.orientation_y = new_or[1];
    ship1.location.orientation_z = new_or[2];

    ship1.refresh();
  }, 150, true)
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
  var ui = {canvas_container    : new CanvasContainer()};
  wire_up_ui(ui, node);

  // restore session
  restore_session(ui, node, function(res){
    custom_operations(ui, node);
  });

  // show the canvas by default
  ui.canvas_container.canvas.show();
});
