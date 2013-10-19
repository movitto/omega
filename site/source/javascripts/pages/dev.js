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

// http://beltoforion.de/galaxy/galaxy_en.html#idRef3
function create_galaxy(ui){
  var particle_size = 30;

  // rotate a series of ellipses of increasing diameter to form galaxy
  var ecurr_rot = 0;
  var eskew  = 1.2;
  var estart = 1;
  var eend = 1000;
  var einc = 15;
  var tinc = 0.05;

  var max_z = 150;

  // render w/ particle system w/ individually colored vertices
  var mat =
    new THREE.ParticleBasicMaterial({size: particle_size, vertexColors: true,
         map: UIResources().load_texture(UIResources().images_path + "/particle.png"),
         blending: THREE.AdditiveBlending, transparent: true });

  // generate vertices positions and colors
  var geo = new THREE.Geometry();

  var mesh = new THREE.ParticleSystem(geo, mat);
  mesh.sortParticles = true;
  mesh.position.set(0,0,0);
  mesh.rotation.set(1.57,0,0)
  //mesh.update_particles = update_galaxy;
  window.setInterval(function(){update_galaxy.apply(mesh,[])},250)

  // reset vertices/colors
  geo.vertices = [];
  geo.colors = [];

  for(var s = estart; s < eend; s += einc) {
    for(var t = 0; t < 2*Math.PI; t += tinc){
      // ellipse
      var x = s * Math.sin(t)
      var y = s * Math.cos(t) * eskew;

      // rotate
      var n = rot(x,y,0,ecurr_rot,0,0,1);

      var x1 = n[0]; var y1 = n[1];
      var d  = Math.sqrt(Math.pow(x1,2)+Math.pow(y1,2))

      // create position vertex
      var pv = new THREE.Vector3(x1, y1, 0);
      pv.ellipse = [s,ecurr_rot];
      geo.vertices.push(pv);

      // randomize z position in bulge
      if(d<100) pv.z = Math.floor(Math.random() * 100);
      else      pv.z = Math.floor(Math.random() * max_z / d*100);

      if(d > 500) pv.z /= 2;
      else if(d > 1500) pv.z /= 3;
      if(Math.floor(Math.random() * 2) == 0) pv.z *= -1;

      // create color, modifing color & brightness based on distance
      var ifa = Math.floor(Math.random() * 15 - (Math.exp(-d/4000) * 5));// 1/2 intensity distance: 4000
      var pc = 0xFFFFFF;
      if(Math.floor(Math.random() * 5) != 0){ // 1/5 particles are white
        if(d > eend/5)
          pc = 0x000DCC;                      // stars far from the center are blue
        else{
          if(Math.floor(Math.random() * 5) != 0){
            var n = Math.floor(Math.random() * 4);
            if(n == 0)
              pc = 0xFF6600;
            else if(n == 1)
              pc = 0xFFCC00;
            else if(n == 2)
              pc = 0xFF0033;
            else if(n == 3)
              pc = 0xCC9900;
          }
        }
      }

      for(var i=0; i < ifa; i++)
        pc = ((pc & 0xfefefe) >> 1);

      geo.colors.push(new THREE.Color(pc));
    }
    ecurr_rot += 0.1;
  }

  return mesh;
}

function update_galaxy(){
  var tinc = 0.02;
  var eskew = 1.2;

  for(var v = 0; v < this.geometry.vertices.length; v++){
    /// get particle
    var vec = this.geometry.vertices[v];
    var d = Math.sqrt(Math.pow(vec.x,2)+Math.pow(vec.y,2)+Math.pow(vec.z,2));

    /// calculate current theta
    var s = vec.ellipse[0]; var rote = vec.ellipse[1];
    var o = rot(vec.x,vec.y,vec.z,-rote,0,0,1);
    var t = Math.asin(o[0]/s);
    if(o[1] < 0) t = Math.PI - t;

    /// rotate it along its elliptical path
        t+= tinc/d*100;
    var x = s * Math.sin(t);
    var y = s * Math.cos(t) * eskew;
    var n = rot(x,y,o[2],rote,0,0,1)

    /// set particle
    vec.set(n[0], n[1], n[2]);
  }

  this.geometry.__dirtyVertices = true;
}

function demo_galaxy(ui, node){
  //var mesh = create_galaxy(ui);
  //ui.canvas_container.canvas.scene.add_component(mesh);

  var sys = new SolarSystem({id : 'sys1', name: 'sys1', location: create_loc(500, 500, 10)});
  var gal = new Galaxy({id : 'gal1', background : 2,  // XXX galaxy1/3 bg crashes ff
                        children : [sys]})
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
