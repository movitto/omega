/* Omega Javascript Planet
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//TODO consolidate alot of calculations here w/ that in common.js

/* Omega Planet
 */
function Planet(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  var planet = this;
  this.json_class = 'Cosmos::Entities::Planet';

  // initialize missing children
  if(!this.moons) this.moons = [];

  // convert location
  this.location = new Location(this.location);
  if(this.children){
    for(var c = 0; c < this.children.length; c++){
      this.moons.push(new Moon(this.children[c]))
    }
  }

  /* override update
   */
  this.old_update = this.update;
  this.update = _planet_update;

  // trigger a blank update to refresh components from current state
  this.refresh = function(){
    this.update(this);
  }

  _planet_load_mesh(this);
  _planet_load_orbit(this);
  _planet_load_moons(this);

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }

  // run planet timer if not already running
  Planet.run_timer.play();
}

/* Planet::update method
 */
function _planet_update(oargs){
  var args = $.extend({}, oargs); // copy args

  if(args.location){
    this.location.update(args.location);
    delete args.location;
  }

  if(this.location){
    if(this.sphere){
      this.sphere.position.x = this.location.x;
      this.sphere.position.y = this.location.y;
      this.sphere.position.z = this.location.z;
    }

    for(var m = 0; m < this.moons.length; m++){
      var moon = this.moons[m];
      var ms   = this.moon_spheres[m];
      if(ms){
        ms.position.x = this.location.x + moon.location.x;
        ms.position.y = this.location.y + moon.location.y;
        ms.position.z = this.location.z + moon.location.z;
      }
    }
  }

  if(this.current_scene)
    this.current_scene.reload_entity(this);

  this.old_update(args);
}

/* Helper to load planet mesh
 */
function _planet_load_mesh(planet){
  // generate mesh texture from color mapping
  var ti = parseInt('0x' + planet.color) % 5;

  // instantiate sphere to draw planet with on canvas
  var sphere_geometry =
    UIResources().cached('planet_sphere_' + planet.size + '_geometry',
      function(i) {
        var radius = planet.size, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_texture =
    UIResources().cached("planet_"+ti+"_sphere_texture",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['planet'+ti]['material'];
        return UIResources().load_texture(path);
      });

  var sphere_material =
    UIResources().cached("planet_sphere_" + planet.color + "_material",
      function(i) {
        return new THREE.MeshLambertMaterial({map: sphere_texture});
      });

  planet.sphere =
    UIResources().cached("planet_" + planet.id + "_sphere_geometry",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = planet.location.x;
        sphere.position.y = planet.location.y;
        sphere.position.z = planet.location.z;
        return sphere;
      });

  planet.clickable_obj = planet.sphere;
  planet.components.push(planet.sphere);
}

/* Helper to load planet orbit
 */
function _planet_load_orbit(planet){
  var ms = planet.location.movement_strategy;
  if(ms == null) return;

  // intercepts
  planet.a = ms.p / (1 - Math.pow(ms.e, 2));
  planet.b = Math.sqrt(ms.p * planet.a);
  planet.le = Math.sqrt(Math.pow(planet.a, 2) - Math.pow(planet.b, 2));

  // orbit center (assuming movement_strategy.relative is set to foci, see elliptical_path)
  planet.cx = -1 * ms.dmajx * planet.le;
  planet.cy = -1 * ms.dmajy * planet.le;
  planet.cz = -1 * ms.dmajz * planet.le;

  // orbit rotation axis
  var nv = cp(ms.dmajx, ms.dmajy, ms.dmajz,
              ms.dminx, ms.dminy, ms.dminz);
  planet.rot_axis_angle = abwn(0, 0, 1, nv[0], nv[1], nv[2]);
  planet.rot_axis = cp(0, 0, 1, nv[0], nv[1], nv[2])
  planet.rot_axis =
    nrml(planet.rot_axis[0], planet.rot_axis[1], planet.rot_axis[2]);

  // calculate the planet's orbit
  planet.orbit =
    UIResources().cached("planet_" + planet.id + "_orbit",
      function(i) {
        return elliptical_path(planet.location.movement_strategy);
      });

  // instantiate line to draw orbit with on canvas
  var orbit_material =
    UIResources().cached("planet_orbit_material",
      function(i) {
        return new THREE.LineBasicMaterial({color: 0xAAAAAA});
      });


  var orbit_geometry =
    UIResources().cached("planet_" + planet.id + "_orbit_geometry",
      function(i) {
        var geometry = new THREE.Geometry();
        var first = null, last = null;
        for(var o = 0; o < planet.orbit.length; o++){
          if(o != 0){ // && (o % 3 == 0)){
            var orbit  = planet.orbit[o];
            var porbit = planet.orbit[o-1];
            if(first == null) first = new THREE.Vector3(porbit[0], porbit[1], porbit[2]);
            last = new THREE.Vector3(orbit[0],  orbit[1],  orbit[2]);
            geometry.vertices.push(last);
            geometry.vertices.push(new THREE.Vector3(porbit[0], porbit[1], porbit[2]));
          }
        }
        geometry.vertices.push(first);
        geometry.vertices.push(last);
        return geometry;
      });

  var orbit_line =
    UIResources().cached("planet_" + planet.id + "_orbit_line",
      function(i) {
        return new THREE.Line(orbit_geometry, orbit_material);
      });

  planet.components.push(orbit_line);
}

/* Helper to load planet moons
 */
function _planet_load_moons(planet){
  // draw spheres representing moons
  var sphere_material =
    UIResources().cached("moon_sphere__material",
      function(i) {
        return new THREE.MeshBasicMaterial({color: 0x808080});
      });

  var sphere_geometry =
    UIResources().cached("moon_sphere_geometry",
      function(i) {
        var mnradius = 5, mnsegments = 32, mnrings = 32;
        return new THREE.SphereGeometry(mnradius, mnsegments, mnrings);
      });


  planet.moon_spheres = [];
  for(var m = 0; m < planet.moons.length; m++){
    var moon = planet.moons[m];
    var sphere =
      UIResources().cached("moon_"+ moon.id +"sphere",
                           function(i) {
                             var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
                             sphere.position.x = planet.location.x + moon.location.x;
                             sphere.position.y = planet.location.y + moon.location.y;
                             sphere.position.z = planet.location.z + moon.location.z;
                             return sphere;
                           });
    planet.components.push(sphere);
    planet.moon_spheres.push(sphere);
  }
}

/* Global planet timer helper
 * that checks for planet movement inbetween
 * notifications from server
 */
function _planet_movement_cycle(){
  var planets = Entities().select(function(e) {
    return e.json_class == 'Cosmos::Entities::Planet';
  });

  // FIXME how to synchronize timing between this and server?
  // TODO only planets in current scene

  for(var p = 0; p < planets.length; p++){
    var pl = planets[p];
    var ms = pl.location.movement_strategy;

    var curr = new Date();
    if(pl.last_moved != null){
      var elapsed = curr - pl.last_moved;
      var dist = ms.speed * elapsed / 1000;

      //rotate to xy plane, skip if not rotated
      var x,y; //z should == 0
      if(pl.rot_axis_angle != 0){
        var n = rot(pl.location.x-pl.cx, pl.location.y-pl.cy, pl.location.z-pl.cz,
                    - pl.rot_axis_angle,
                    pl.rot_axis[0], pl.rot_axis[1], pl.rot_axis[2])
        x = n[0] ; y = n[1];
      }else{
       x = pl.location.x-pl.cx; y = pl.location.y - pl.cy;
      }

      // calc intercepts / current angle (x = a*Math.cos(i))
      //var angle = Math.atan2(y,x)
      //if(angle < 0) angle += 2*Math.PI;
      var angle = Math.acos(x/pl.a)
      if(y < 0) angle = 2 * Math.PI - angle;

      // calculate new angle
      var new_angle = dist + angle;

      // calculate new position
      var x = pl.a * Math.cos(new_angle);
      var y = pl.b * Math.sin(new_angle);
      var n;
      if(pl.rot_axis_angle != 0){
        n = rot(x,y,0,
                pl.rot_axis_angle,
                pl.rot_axis[0],pl.rot_axis[1],pl.rot_axis[2])
      }else{
        n[0] = x; n[1] = y; n[2] = 0;
      }
      pl.location.x = n[0] + pl.cx;
      pl.location.y = n[1] + pl.cy;
      pl.location.z = n[2] + pl.cz;

      pl.refresh();
    }
    pl.last_moved = curr;
  }
}

Planet.run_timer = $.timer(function(){
  _planet_movement_cycle();
}, 150, false);
