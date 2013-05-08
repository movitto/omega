/* dev page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega"

// do whatever you would like to here
var custom_operations = function(ui, node){
  ui.canvas.scene.skybox.background('galaxy1');
  ui.canvas.scene.add_component(ui.canvas.scene.skybox.components[0]);

  //var loc1    = new Location({ x : 0, y : 0, z : 0,
  //                            orientation_x : 0,
  //                            orientation_y : 1,
  //                            orientation_z : 0})
  //var ship1 = new Ship({id : 'ship1', location : loc1, hp : 50, type : 'destroyer'});
  //ui.canvas.scene.add_entity(ship1);

  //var loc2    = new Location({ x : 200, y : 200, z : 0,
  //                            orientation_x : 1,
  //                            orientation_y : 0,
  //                            orientation_z : 0})
  //var ship2 = new Ship({id : 'ship2', location : loc2, hp : 50, type : 'corvette'});
  //ui.canvas.scene.add_entity(ship2);

  //var loc3    = new Location({ x : -200, y : -200, z : 0,
  //                            orientation_x : 0,
  //                            orientation_y : 0,
  //                            orientation_z : 1})
  //var ship3 = new Ship({id : 'ship3', location : loc3, hp : 50, type : 'mining'});
  //ui.canvas.scene.add_entity(ship3);

  //var loc4    = new Location({ x : 400, y : 400, z : 0,
  //                            orientation_x : 0,
  //                            orientation_y : 0,
  //                            orientation_z : -1})
  //var ship4 = new Ship({id : 'ship4', location : loc4, hp : 50, type : 'transport'});
  //ui.canvas.scene.add_entity(ship4);


  //var locs    = new Location({ x : 0, y : 0, z : 0 });
  //var star    = new Star({location : locs, id : 'star1', color : '878787', size: 500})
  //ui.canvas.scene.add_entity(star);

  //var locp    = new Location({ x : 0, y : 0, z : 0 });
  //var planet  = new Planet({location : locp, id : 'planet1', color : 'abcde6', size: 500})
  //ui.canvas.scene.add_entity(planet);

  //var loca     = new Location({ x : 0, y : 0, z : 0 });
  //var asteroid = new Asteroid({location : loca, id : 'asteroid1'})
  //ui.canvas.scene.add_entity(asteroid);

  var locj = new Location({ x : 0, y : 0, z : 0 });
  var jg   = new JumpGate({location : locj, id : 'jump_gate1'})
  //ui.canvas.scene.add_entity(jg);

  var locsy1 = new Location({ x : 0, y : 0, z : 0 });
  var sys1   = new SolarSystem({location : locsy1, name : 'system1'})
  ui.canvas.scene.add_entity(sys1);

  var locsy2 = new Location({ x : 500, y : 500, z : -500 });
  var sys2   = new SolarSystem({location : locsy2, name : 'system2'})
  ui.canvas.scene.add_entity(sys2);

  sys1.add_jump_gate(jg, sys2);

  //var geo   = new THREE.PlaneGeometry(300, 300);

  //var path = UIResources().images_path +
  //           $omega_config.resources['solar_system']['material'];
  //var tex = UIResources().load_texture(path);
  //var mat = new THREE.MeshBasicMaterial({color: 0x0000CC, //map: plane_texture,
  //                                       alphaTest: 0.5});
  //mat.side = THREE.DoubleSide;

  //var plane = new THREE.Mesh(geo, mat);
  //plane.position.x = plane.position.y = plane.position.z = 0
  //plane.rotation.x = -0.785;
  //ui.canvas.scene.add_component(plane);

  ui.canvas.scene.animate();
}

// initialize the page
$(document).ready(function(){ 
  // initialize top level components
  var ui   = new UI();
  var node = new Node();

  node.on_error(function(e){
    // log all errors to the console
    console.log(e);
  });

  // setup interface and restore session
  wire_up_ui(ui, node);
  restore_session(ui, node, function(res){
    custom_operations(ui, node);
  });

  // show the canvas by default
  ui.canvas.show();
});
