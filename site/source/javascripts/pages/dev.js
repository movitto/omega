/* dev page
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "ui/containers"
//= require "omega"

var loc_id = 0;
function create_loc(x,y,z, ms){
  loc_id += 1;
  var oor = [0,0,1];
  if(ms == null)
    ms = { json_class : 'Motel::MovementStrategies::Stopped' }; 
  var loc  = new Location({ id : loc_id, x : x, y : y, z : z,
                            orientation_x : oor[0],
                            orientation_y : oor[1],
                            orientation_z : oor[2],
                            movement_strategy : ms})
  return loc;
}

function add_entity(ui, entity){
  ui.canvas_container.canvas.scene.add_entity(entity);
}

function asteroid_field(ui, locations){
  for(var l = 0; l < locations.length; l++){
    var ast = new Asteroid({id : 'ast' + l, location : locations[l]});
    add_entity(ui, ast)
  }
}

function asteroid_belt(ui, ms){
  var locs = [];
  var path = elliptical_path(ms);
  var nlocs = Math.floor(path.length / 30);
  for(var l = 0; l < 30; l++){
    var pp = path[nlocs * l];
    locs.push(create_loc(pp[0],pp[1],pp[2]));
  }

  asteroid_field(ui, locs);
}

function ellipse_ms(nrml, opts){
  // generate major axis such that maj . nrml = 0
  var majx = Math.random();
  var majy = Math.random();
  var majz = (majx * nrml.x + majy * nrml.y) / -nrml.z;

  // rotate maj axis by 1.57 around nrml to get min
  var min = rot(majx,majy,majz,1.57,nrml.x,nrml.y,nrml.z)
  var minx = min[0]; var miny = min[1]; var minz = min[2];

  return $.extend({dmajx : majx, dmajy : majy, dmajz : majz,
                   dminx : minx, dminy : miny, dminz : minz}, opts);
}

function demo_system(ui, node){
  var star1 = new Star({id : 'star1', color: 'FFFF00', size: 550,
                        location: create_loc(0,0,0)});

  var jump_gate1 = new JumpGate({id : 'jg1', location : create_loc(2300,0,0)});

  // generate different orbits w/ the same normal
  var orbit_nrml  = {x : 0.68, y : -0.56, z : 0.45}

  var pl1ms = ellipse_ms(orbit_nrml, {p: 3000, speed: 0.01, e : 0.7, })
  var planet1 = new Planet({id : 'planet1', size: 50, color: 'ABABAB', location : create_loc(1800,0,0,pl1ms)});

  var pl2ms = ellipse_ms(orbit_nrml, {p: 6500, speed: -0.008, e : 0.58, })
  var planet2 = new Planet({id : 'planet2', size: 100, color: 'CBCBAB', location : create_loc(2000,0,0,pl2ms)});

  var abms = ellipse_ms(orbit_nrml, {p : 5000, e : 0.62});

  var sys = new SolarSystem({id : 'sys1', background : 1,
                             children : [jump_gate1, star1, planet1, planet2]})
  jump_gate1 = sys.jump_gates[0];
  star1      = sys.stars[0];
  // XXX breaks things:
  //planet1    = sys.planets[0];
  //planet2    = sys.planets[1];

  var sh1ms  = {json_class : 'Motel::MovementStrategies::Stopped'};
  var ship1 = new Ship({id : 'ship1', hp : 50, type : 'mining',
                        location : create_loc(1500,0,0,sh1ms), system_id : 'sys1'});

  var sh1ams  = {json_class : 'Motel::MovementStrategies::Stopped'};
  var ship1a = new Ship({id : 'ship1a', hp : 50, type : 'mining',
                        location : create_loc(1900,0,0,sh1ams), system_id : 'sys1'});

  var sh2ms  = {json_class : 'Motel::MovementStrategies::Stopped'};
  var ship2 = new Ship({id : 'ship2', hp : 50, type : 'corvette',
                        location : create_loc(1700,0,0,sh2ms), system_id : 'sys1'});

  var station1 = new Station({id : 'station1', type : 'manufacturing',
                              location : create_loc(1300,0,0), system_id : 'sys1'});

  Entities().set(planet1.id, planet1)
  Entities().set(planet2.id, planet2)
  Entities().set(jump_gate1.id, jump_gate1);
  handle_events(ui, node, jump_gate1);

  process_entity(ui, node, ship1)
  process_entity(ui, node, ship1a)
  process_entity(ui, node, ship2)
  process_entity(ui, node, station1);

  set_scene(ui, node, sys);

  asteroid_belt(ui, abms);

  ui.canvas_container.canvas.scene.animate();
}

function demo_galaxy(ui, node){
  var sys1 = new SolarSystem({id : 'sys1', name: 'sys1', location: create_loc(500, 500, -40)});
  var sys2 = new SolarSystem({id : 'sys2', name: 'sys2', location: create_loc(500, -500, -40)});
  var gal = new Galaxy({id : 'gal1', background : 2,  // XXX galaxy1/3 bg crashes ff
                        children : [sys1,sys2]})
  gal.solar_systems[0].add_jump_gate({id : 'jg1'}, sys2);
  ui.canvas_container.canvas.scene.add_component(gal.mesh);
  set_scene(ui, node, gal);
}

function custom_operations(ui, node){
  demo_galaxy(ui, node);
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
