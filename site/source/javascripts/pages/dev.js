/* dev page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/containers"
//= require "omega"

function create_loc(x,y,z, ms){
  var oor = [0,0,1];
  if(ms == null)
    ms = { json_class : 'Motel::MovementStrategies::Stopped' }; 
  var loc  = new Location({ x : x, y : y, z : z,
                            orientation_x : oor[0],
                            orientation_y : oor[1],
                            orientation_z : oor[2],
                            movement_strategy : ms})
  return loc;
}

function add_entity(ui, entity){
  ui.canvas_container.canvas.scene.add_entity(entity);
}

function custom_operations(ui, node){
  ui.canvas_container.canvas.scene.skybox.background('system1'); // XXX galaxy1, ... crashes ff
  ui.canvas_container.canvas.scene.add_component(ui.canvas_container.canvas.scene.skybox.components[0]);

  var star1 = new Star({id : 'star1', color: 'FFFFFF', size: 550,
                        location: create_loc(0,0,0)});
  add_entity(ui, star1);

  var shms  = {json_class : 'Motel::MovementStrategies::Linear'};
  var ship1 = new Ship({id : 'ship1', hp : 50, type : 'corvette',
                        location : create_loc(1500,0,0,shms)});
  add_entity(ui, ship1);

  //var station1 = new Station({id : 'station1', type : 'manufacturing',
  //                            location : create_loc(-500,0,0)});
  //ui.canvas_container.canvas.scene.add_entity(station1);

  var plms = {json_class: 'Motel::MovementStrategies::Elliptical',
              p: 3000, e : 0.6, dmajx : 1, dmajy : 0, dmajz : 0,
              dminx : 0, dminy : 0, dminz : 1, speed: 0.01}
  var planet1 = new Planet({id : 'planet1', size: 50, color: 'ABABAB', location : create_loc(1800,0,0,plms)});
  Entities().set(planet1.id, planet1)
  add_entity(ui, planet1);

  //var jump_gate1 = new JumpGate({id : 'jg1', location : create_loc(-1000,0,0)});
  //ui.canvas_container.canvas.scene.add_entity(jump_gate1);

  //var ast1 = new Asteroid({id : 'ast1', size: 100, location : create_loc(-1500,0,0)});
  //ui.canvas_container.canvas.scene.add_entity(ast1);

  //var loc7    = new Location({ x : -600, y : 0, z : 0,
  //                            movement_strategy : { json_class : 'Motel::MovementStrategies::Stopped' }})
  //var sys1 = new SolarSystem({id : 'sys1', location : loc7);
  //ui.canvas_container.canvas.scene.add_entity(sys1);

  //ui.canvas_container.canvas.scene.camera.position({x : 0, y : 150, z : 400})
  //ui.canvas_container.canvas.scene.camera.focus({x : 0, y : 0, z : 0})
  //ui.canvas_container.canvas.scene.camera.rotate(0, 3.14)
  //ui.canvas_container.canvas.scene.camera.zoom(-500);
  ui.canvas_container.canvas.scene.animate();
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
