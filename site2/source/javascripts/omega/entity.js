/* Omega Entity Tracker
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// public methods

/* Register method to be invoked whenever a entity is
 * registered with the tracker
 */
function on_entity_registration(callback){
  $entity_registered_callbacks.push(callback);
}

/////////////////////////////////////// private methods

// clear entity timers
function clear_entity_timers(){
  for(var timer in $timers){
    $timers[timer].stop();
    delete $timers[timer];
  }
  $timers = [];
}

// add entity timer
function add_entity_timer(id, time, callback){
  $timers[id] = $.timer(callback);
  $timers[id].set({time : time, autostart : true });
}


// retrieve the entities owned by the current user
function get_user_entities(){
  omega_entities_owned_by($user_id, get_entities_systems);
}

// retrieve the systems associated with entities
function get_entities_systems(entities){
  for(var entityI in entities){
    var entity = entities[entityI];
    var system = $tracker.load('Cosmos::SolarSystem', entity.system_name, get_system_entities);
    if(system){
      system.update_children();
    }
  }
}

// get additional entities under system
function get_system_entities(system){
  omega_entities_under(system.name);
}

// helper method
function roundTo(number, places){
  return Math.round(number * Math.pow(10,places)) / Math.pow(10,places);
}

// will be set to entity clicked / selected
$selected_entity = null;

// encapsulates server side entity
function OmegaEntity(sentity){
  oentity = {dirty : false};

  oentity.update_children = function(){
    // set child entities
    if(this.location){
      this.children = [];
      for(var child in $tracker.entities){
        child = $tracker.entities[child];
        if(child.location && this.location.id == child.location.parent_id){
          this.children.push(child);
        }
      }
    }
  },

  oentity.update = function(entity){
    for(var p in entity)
      this[p] = entity[p];
    this.dirty = true;
    this.modified = true;

    if(this.location){
      this.location.to_s = function(){ return roundTo(this.x, 2) + "/" + roundTo(this.y, 2) + "/" + roundTo(this.z, 2); }
      this.location.toJSON = function(){ return new JRObject("Motel::Location", this, 
           ["toJSON", "json_class", "entity", "movement_strategy", "notifications",
            "movement_callbacks", "proximity_callbacks"]).toJSON(); };
      this.location.clone = function(){
        var ret = {};
        ret.x = this.x; ret.y = this.y; ret.z = this.z;
        ret.parent_id = this.parent_id; ret.movement_strategy = this.movement_strategy;
        ret.to_s = this.to_s; ret.toJSON = this.toJSON;
        return ret;
      };
    }

    //this.update_children();

    // XXX hacks
    if(entity.name != null && this.id == null)
      this.id = entity.name;
    if($selected_entity && $selected_entity.id == this.id)
      $selected_entity.clicked();

    if(this.updated) this.updated();
  };

  oentity.is_a = function(type){
    return this.json_class == type;
  };

  oentity.belongs_to_user = function(){
    return this.user_id == $user_id;
  };

  oentity.distance_from = function(x, y, z){
    return Math.sqrt(Math.pow(this.location.x - x, 2) +
                     Math.pow(this.location.y - y, 2) +
                     Math.pow(this.location.z - z, 2));
  };

  oentity.is_within = function(distance, location){
    if(this.location == null || this.location.parent_id != location.parent_id)
      return false 
    return  this.distance_from(location.x, location.y, location.z) < distance;
  };

  // entity scene properties
  oentity.load = null; // assign method to load entity resources
  oentity.clicked = null; // assign method to handle entity clicked event
  oentity.clickable_obj = null;
  oentity.scene_objs = [];

  oentity.update(sentity);
  oentity.modified = false;
  return oentity;
}

OmegaEntity.entity_id = function(entity){
  if(entity.id != null) return entity.id;
  if(entity.name != null) return entity.name;
  return null;
}

// global entity registry
$tracker = {
  entities : [],

  has : function(entity_id){
    return this.entities[entity_id] != null;
  },

  // adds entity to tracker if new, else update existing entity
  add : function(entity){
console.log(entity);
    var is_new = false;
    var entity_id = OmegaEntity.entity_id(entity);
    if(this.entities[entity_id] == null){
      is_new = true;
      this.entities[entity_id] = new OmegaEntity(entity);
    }else{
      this.entities[entity_id].update(entity);
    }

    return is_new;
  },

  // returns entity if present, else load it from server and return
  // takes optional callback to invoke if/when server side entity is retrieved
  load : function(type, entity_id, callback){
    if(this.entities[entity_id] != null){
      if(callback != null)
        callback(this.entities[entity_id], null);
      return this.entities[entity_id];
    }

    if(type == "Cosmos::SolarSystem"){
      omega_system(entity_id, function(system){
        $tracker.add(system);
        system = $tracker.entities[system.name];
        if(callback != null) callback(system);
      });
    }else if(type == "Manufactured::Ship" || type == "Manufactured::Station"){
      omega_entity(entity_id, function(entity){
        $tracker.add(entity);
        entity = $tracker.entities[entity.id];
        if(callback != null) callback(entity);
      });
    }

    return null;
  },

  matching_entities : function(args){
    var ret = [];
    for(var entity in this.entities){
      var matched = true;
      if(args.id   && this.entities[entity].id != args.id)
        matched = false;
      if(args.type && this.entities[entity].json_class != args.type)
        matched = false;
      if(args.within && !this.entities[entity].is_within(args.within[0], args.within[1]))
        matched = false;
      if(args.owned_by && this.entities[entity].user_id != args.owned_by)
        matched = false;
      if(args.not_owned_by && this.entities[entity].user_id == args.not_owned_by)
        matched = false;
      if(args.location && (!this.entities[entity].location || this.entities[entity].location.id != args.location))
        matched = false;

      if(matched)
        ret.push(this.entities[entity]);
    }
    return ret;
  }
}

///////////////////////////////// specified entity logic

function register_entity(entity){
  // add to tracker
  $tracker.add(entity);
  entity = $tracker.entities[entity.id || entity.name];

  // invoke entity registered callbacks
  for(var cb in $entity_registered_callbacks){
    cb = $entity_registered_callbacks[cb];
    cb(entity);
  }

  // register subentities and update children
  if(entity.json_class == "Cosmos::Galaxy"){
    for(var sys in entity.solar_systems){
      sys = entity.solar_systems[sys];
      register_entity(sys);
    }
  }else if(entity.json_class == "Cosmos::SolarSystem"){
    if(entity.star != null) register_entity(entity.star);
    for(var a in entity.asteroids) register_entity(entity.asteroids[a]);
    for(var p in entity.planets){
      p = entity.planets[p];
      register_entity(p);
    }
    for(var j in entity.jump_gates){
      j = entity.jump_gates[j];
      j.id = j.solar_system + "-" + j.endpoint;
      register_entity(j);
    }
    entity.update_children();

  }else if(entity.json_class == "Cosmos::Planet"){
    for(var m in entity.moons)
      register_entity(entity.moons[m]);
    entity.update_children();
  }
}

function load_entity(entity){
  if(entity.json_class == "Cosmos::SolarSystem"){
    entity.clicked        = clicked_system;
    entity.load           = load_system;

  }else if(entity.json_class == "Cosmos::Star"){
    entity.clicked = clicked_star;
    entity.load  = load_star;

  }else if(entity.json_class == "Cosmos::Planet"){
    entity.clicked = clicked_planet;
    entity.load  = load_planet;
    entity.updated = updated_planet;
    entity.added_to_scene = added_planet_to_scene;

  }else if(entity.json_class == "Cosmos::Asteroid"){
    entity.clicked = clicked_asteroid;
    entity.load  = load_asteroid;

  }else if(entity.json_class == "Cosmos::JumpGate"){
    entity.clicked = clicked_jump_gate;
    entity.load = load_jump_gate;

  }else if(entity.json_class == "Manufactured::Ship"){
    entity.clicked = clicked_ship;
    entity.load  = load_ship;
    entity.updated = updated_ship;
    entity.added_to_scene = added_ship_to_scene;

  }else if(entity.json_class == "Manufactured::Station"){
    entity.clicked = clicked_station;
    entity.load  = load_station;
  }

  entity.load();
}

function load_system(){
  var system = this;
  var loc    = system.location;

  for(var j=0; j<system.jump_gates.length;++j){
    var jg = system.jump_gates[j];
    var endpoint = $tracker.load(jg.endpoint);

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(endpoint.x, endpoint.y, endpoint.z));
    var line = new THREE.Line(geometry, $scene.materials['line']);
    system.scene_objs.push(line);
    $scene._scene.add(line);
  }
  
  // draw sphere representing system
  var radius = system.size, segments = 32, rings = 32;
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $scene.materials['system']);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  system.clickable_obj = sphere;
  system.scene_objs.push(sphere);
  $scene._scene.add(sphere);

  // draw label
  var text3d = new THREE.TextGeometry( system.name, {height: 10, width: 3, curveSegments: 2, font: 'helvetiker', size: 16});
  var text = new THREE.Mesh( text3d, $scene.materials['system_label'] );
  text.position.x = loc.x - 50 ; text.position.y = loc.y - 50 ; text.position.z = loc.z - 50;
  text.lookAt($camera._camera.position);
  system.scene_objs.push(text);
  $scene._scene.add(text);

  system.load = null;
}

function clicked_system(){
  var system = this;
  set_root_entity(system.name);
}

function load_star(){
  var star = this;
  var loc  = star.location;

  var radius = star.size, segments = 32, rings = 32;

  if($scene.materials['star' + star.color] == null)
    $scene.materials['star' + star.color] = new THREE.MeshLambertMaterial({color: parseInt('0x' + star.color), blending: THREE.AdditiveBlending })
  var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $scene.materials['star' + star.color]);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  star.clickable_obj = sphere;
  star.scene_objs.push(sphere);
  $scene._scene.add(sphere);

  star.load = null;
}

function clicked_star(){
}

function calc_orbit(planet){
  planet.orbit = [];
  // intercepts
  var a = planet.location.movement_strategy.semi_latus_rectum / (1 - Math.pow(planet.location.movement_strategy.eccentricity, 2));
  var b = Math.sqrt(planet.location.movement_strategy.semi_latus_rectum * a);
  // linear eccentricity
  var le = Math.sqrt(Math.pow(a, 2) - Math.pow(b, 2));
  // center (assumes planet's location's movement_strategy.relative to is set to foci
  var cx = -1 * planet.location.movement_strategy.direction_major_x * le;
  var cy = -1 * planet.location.movement_strategy.direction_major_y * le;
  var cz = -1 * planet.location.movement_strategy.direction_major_z * le;
  // orbit
  for(var i = 0; i < 2 * Math.PI; i += (Math.PI / 180)){
    var ox = cx + a * Math.cos(i) * planet.location.movement_strategy.direction_major_x +
                  b * Math.sin(i) * planet.location.movement_strategy.direction_minor_x ;
    var oy = cy + a * Math.cos(i) * planet.location.movement_strategy.direction_major_y +
                  b * Math.sin(i) * planet.location.movement_strategy.direction_minor_y ;
    var oz = cz + a * Math.cos(i) * planet.location.movement_strategy.direction_major_z +
                  b * Math.sin(i) * planet.location.movement_strategy.direction_minor_z ;
    var absi = parseInt(i * 180 / Math.PI);
    if(planet.orbiti == null ||
       planet.distance_from(ox, oy, oz) < planet.distance_from.apply(planet, planet.orbit[absi-1])){
        planet.orbiti = absi;
    }
    planet.orbit.push([ox, oy, oz]);
  }

  planet.move = function(){
    var now = (new Date()).getTime() / 1000;
    if(this.last_moved == null){
      this.last_moved = now;
      return;
    }
    var elapsed = now - this.last_moved;
    var distance = this.location.movement_strategy.speed * elapsed;
    this.last_moved = now;

    var absd = parseInt(distance * 180 / Math.PI);
    this.orbiti += absd;
    if(this.orbiti > 360) this.orbiti -= 360;
    var nloc = this.orbit[this.orbiti];
    this.location.x = nloc[0]; this.location.y = nloc[1]; this.location.z = nloc[2];
    this.updated();
  }

}

function load_planet(){
  var planet = this;
  var loc    = planet.location;
  calc_orbit(planet);

  // draw sphere representing planet
  var radius = planet.size, segments = 32, rings = 32;
  if($scene.geometries['planet' + radius] == null)
    $scene.geometries['planet' + radius] = new THREE.SphereGeometry(radius, segments, rings);
  if($scene.materials['planet' + planet.color] == null)
    $scene.materials['planet' + planet.color] = new THREE.MeshLambertMaterial({color: parseInt('0x' + planet.color), blending: THREE.AdditiveBlending});
  var sphere = new THREE.Mesh($scene.geometries['planet' + radius],
                              $scene.materials['planet' + planet.color]);
  sphere.position.x = loc.x ; sphere.position.y = loc.y ; sphere.position.z = loc.z ;
  planet.clickable_obj = sphere;
  planet.scene_objs.push(sphere);
  $scene._scene.add(sphere);

  // draw orbit
  var geometry = new THREE.Geometry();
  for(var o in planet.orbit){
    if(o != 0 & (o % 10 == 0)){
      var orbit  = planet.orbit[o];
      var porbit = planet.orbit[o-1];
      geometry.vertices.push(new THREE.Vector3(orbit[0],  orbit[1],  orbit[2]));
      geometry.vertices.push(new THREE.Vector3(porbit[0], porbit[1], porbit[2]));
    }
  }
  var line = new THREE.Line(geometry, $scene.materials['orbit']);
  planet.scene_objs.push(line);
  planet.scene_objs.push(geometry);
  // !FIXME! rendering orbits results in a big performance hit,
  // need to figure out a better way and/or make this togglable
  $scene._scene.add(line);
  // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  // draw moons
  for(var m=0; m<planet.moons.length; ++m){
    var moon = planet.moons[m];
    var sphere = new THREE.Mesh($scene.geometries['moon'], $scene.materials['moon']);
    sphere.position.x = loc.x + moon.location.x ; sphere.position.y = loc.y + moon.location.y; sphere.position.z = loc.z + moon.location.z;
    moon.scene_obj = sphere;
    planet.scene_objs.push(sphere);
    $scene._scene.add(sphere);
  }

  planet.load = null;
}

function updated_planet(){
  var di = this.distance_from.apply(this, this.orbit[this.orbiti]);

  for(var i = 0; i < 2 * Math.PI; i += (Math.PI / 180)){
    var absi = parseInt(i * 180 / Math.PI);
    if(this.distance_from.apply(this, this.orbit[i]) < di){
        this.orbiti = absi;
    }
  }

  this.clickable_obj.position.x = this.location.x;
  this.clickable_obj.position.y = this.location.y;
  this.clickable_obj.position.z = this.location.z;

  for(var m=0; m<this.moons.length; ++m){
    var moon = this.moons[m];
    moon.scene_obj.position.x = this.location.x + moon.location.x;
    moon.scene_obj.position.y = this.location.y + moon.location.y;
    moon.scene_obj.position.z = this.location.z + moon.location.z;
  }
}

function clicked_planet(){
}

function added_planet_to_scene(){
  omega_ws_request('motel::remove_callbacks', child.location.id,      null);
  omega_ws_request('motel::track_movement',   child.location.id, 120, null);
}

function load_asteroid(){
  var asteroid = this;
  var loc      = asteroid.location;

  var text = new THREE.Mesh( $scene.geometries['asteroid'], $scene.materials['asteroid'] );
  text.position.x = loc.x ; text.position.y = loc.y ; text.position.z = loc.z;
  asteroid.clickable_obj = text;
  asteroid.scene_objs.push(text);
  $scene._scene.add(text);

  asteroid.load = null
}

function clicked_asteroid(){
  var asteroid = this;
  var details = ['Asteroid: ' + asteroid.name + "<br/>",
                 '@ ' + asteroid.location.to_s() + '<br/>',
                 'Resources: <br/>'];
  show_entity_container(details);

  omega_web_request('cosmos::get_resource_sources', asteroid.name, function(resource_sources, error){
    if(error == null){
      var details = [];
      for(var r in resource_sources){
        var res = resource_sources[r];
        details.push(res.quantity + " of " + res.resource.name + " (" + res.resource.type + ")<br/>");
      }
      append_to_entity_container(details);
    }
  });
}

function load_jump_gate(){
  var jump_gate = this;
  var loc       = jump_gate.location;

  var geometry = new THREE.PlaneGeometry( 50, 50 );
  var mesh = new THREE.Mesh( geometry, $scene.materials['jump_gate'] );
  mesh.position.set( loc.x, loc.y, loc.z );
  jump_gate.scene_objs.push(mesh);
  jump_gate.scene_objs.push(geometry);
  $scene._scene.add( mesh );

  // sphere to draw around jump gate when selected
  var radius = jump_gate.trigger_distance, segments = 32, rings = 32;
  var ssphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $scene.materials['jump_gate_selected'] );
  ssphere.position.x = loc.x ; ssphere.position.y = loc.y ; ssphere.position.z = loc.z ;
  jump_gate.scene_objs.push(ssphere);

  if(jump_gate.selected){
    $scene._scene.add(ssphere);
    jump_gate.clickable_obj = ssphere;
  }else{
    jump_gate.clickable_obj = mesh;
  }
  jump_gate.load = null;
}

function unselect_jump_gate(jump_gate){
  $selected_entity = null;
  jump_gate.selected = false;
  jump_gate.dirty = true;
  $scene.reload(jump_gate);
  $entity_container_callback = null;
}

function clicked_jump_gate(){
  var jump_gate = this;

  // TODO wire up trigger handler
  var details =
    ['Jump Gate to ' + jump_gate.endpoint + '<br/>',
     '@ ' + jump_gate.location.to_s() + "<br/><br/>",
     "<div class='cmd_icon' id='ship_trigger_jg'>Trigger</div>"];
  show_entity_container(details); // XXX should go before the following as it will invoke hide_entity_container / unselect_jump_gate
  $selected_entity = jump_gate;
  jump_gate.selected = true;
  jump_gate.dirty = true;
  $scene.reload(jump_gate);
  $entity_container_callback = function(){ unselect_jump_gate(jump_gate); };
}

function load_ship(){
  var ship = this;
  var loc  = ship.location;

  // do not load if ship is destroyed
  if(ship.hp <= 0)
    return;

  // draw crosshairs representing ship
  var color = '0x';
  if(ship.selected)
    color += "FFFF00";
  else if(ship.docked_at)
    color += "99FFFF";
  else if(!ship.belongs_to_user())
    color += "CC0000";
  else
    color += "00CC00";

  if($scene.materials['ship' + color] == null)
    $scene.materials['ship' + color] = new THREE.LineBasicMaterial({color: parseInt(color)});

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x - ship.size/2, loc.y, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x + ship.size/2, loc.y, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['ship' + color]);
  ship.scene_objs.push(line);
  ship.scene_objs.push(geometry);
  $scene._scene.add(line);

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y - ship.size/2, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y + ship.size/2, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['ship' + color]);
  ship.scene_objs.push(line);
  ship.scene_objs.push(geometry);
  $scene._scene.add(line);

  var geometry = new THREE.PlaneGeometry( ship.size, ship.size );
  //var texture = new THREE.MeshFaceMaterial();
  var mesh = new THREE.Mesh(geometry, $scene.materials['ship_surface']);
  mesh.position.set(loc.x, loc.y, loc.z);
  ship.scene_objs.push(mesh);
  ship.scene_objs.push(geometry);
  $scene._scene.add(mesh);

  ship.clickable_obj = mesh;

  // if ship is attacking another, draw line of attack
  if(ship.attacking){
    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(ship.attacking.location.x, ship.attacking.location.y + 25, ship.attacking.location.z));
    line = new THREE.Line(geometry, $scene.materials['ship_attacking']);
    ship.scene_objs.push(line);
    ship.scene_objs.push(geometry);
    $scene._scene.add(line);
  }

  // if ship is mining, draw line to mining target
  if(ship.mining){
    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(loc.x, loc.y, loc.z));
    geometry.vertices.push(new THREE.Vector3(ship.mining.entity.location.x, ship.mining.entity.location.y + 25, ship.mining.entity.location.z));
    line = new THREE.Line(geometry, $scene.materials['ship_mining']);
    ship.scene_objs.push(line);
    ship.scene_objs.push(geometry);
    $scene._scene.add(line);
  }

  ship.load = null;
}

function updated_ship(){
  // TODO simple refresh coordinates / properties instead of removing
  // and readding all of the ship's scene objects
  if($scene.has(this))
    $scene.reload(this);
}

function unselect_ship(ship){
  $selected_entity = null;
  ship.selected = false;
  ship.dirty = true;
  $scene.reload(ship);
  $entity_container_callback = null;
}

function clicked_ship(){
  var ship = this;

  var details = ['Ship: ' + ship.id + "<br/>", '@ ' + ship.location.to_s() + '<br/>'];

  var txt = 'Resources: <br/>';
  for(var r in ship.resources){
    txt += ship.resources[r] + " of " + r + ", ";
  }
  details.push(txt);

  if(ship.belongs_to_user()){
    details.push("<div class='cmd_icon' id='ship_select_move'>move</div>"); // TODO only if not mining / attacking
    details.push("<div class='cmd_icon' id='ship_select_target'>attack</div>");
    details.push("<div class='cmd_icon' id='ship_select_dock'>dock</div>");
    details.push("<div class='cmd_icon' id='ship_undock'>undock</div>");
    details.push("<div class='cmd_icon' id='ship_select_transfer'>transfer</div>");
    details.push("<div class='cmd_icon' id='ship_select_mine'>mine</div>");
  }

  show_entity_container(details);

  if(!ship.docked_at){
    $('#ship_select_dock').show();
    $('#ship_undock').hide();
    $('#ship_select_transfer').hide();
  }else{
    $('#ship_select_dock').hide();
    $('#ship_undock').show();
    $('#ship_select_transfer').show();
  }

  $selected_entity = ship;
  ship.selected = true;
  ship.dirty = true;
  $entity_container_callback = function(){ unselect_ship(ship); };
  $scene.reload(ship);
}

function added_ship_to_scene(){
  // remove & resetup callbacks
  omega_ws_request('motel::remove_callbacks',        this.location.id,                       null);
  omega_ws_request('manufactured::remove_callbacks', this.id,                                null);
  omega_ws_request('motel::track_movement',          this.location.id, 20,                   null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'resource_collected', null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'mining_stopped',     null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'attacked',           null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'attacked_stop',      null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'defended',           null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'defended_stop',      null);
  omega_ws_request('manufactured::subscribe_to',     this.id,          'destroyed',          null);
}

function load_station(){
  var station = this;
  var loc     = station.location;

  var color = '0x';
  if(station.selected)
    color += "FFFF00";
  else if(!station.belongs_to_user())
    color += "CC0011";
  else
    color += "0000CC";

  if($scene.materials['station' + color] == null)
    $scene.materials['station' + color] = new THREE.LineBasicMaterial({color: parseInt(color)});

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x - station.size/2, loc.y, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x + station.size/2, loc.y, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['station'+color]);
  station.scene_objs.push(line);
  $scene._scene.add(line);

  var geometry = new THREE.Geometry();
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y - station.size/2, loc.z));
  geometry.vertices.push(new THREE.Vector3(loc.x, loc.y + station.size/2, loc.z));
  var line = new THREE.Line(geometry, $scene.materials['station'+color]);
  station.scene_objs.push(line);
  station.scene_objs.push(geometry);
  $scene._scene.add(line);

  var geometry = new THREE.PlaneGeometry( station.size, station.size );
  var mesh = new THREE.Mesh(geometry, $scene.materials['station_surface']);
  mesh.position.set(loc.x, loc.y, loc.z);
  station.scene_objs.push(mesh);
  station.scene_objs.push(geometry);
  $scene._scene.add(mesh);

  station.clickable_obj = mesh;
}

function unselect_station(station){
  $selected_entity = null;
  station.selected = false;
  station.dirty = true;
  $scene.reload(station);
  $entity_container_callback = null;
}

function clicked_station(){
  var station = this;

  var details = ['Station: ' + station.id + "<br/>", '@' + station.location.to_s() + '<br/>'];

  var txt = 'Resources: <br/>';
  for(var r in station.resources){
    txt += station.resources[r] + " of " + r + ", ";
  }
  details.push(txt);

  if(station.belongs_to_user()){
    // TODO wire up construction handler
    details.push("<div class='cmd_icon' id='station_select_construction'>construct</div>");
  }
  show_entity_container(details);

  $selected_entity = station;
  station.selected = true;
  station.dirty = true;
  $entity_container_callback = function(){ unselect_station(station); };
  $scene.reload(station);
}

/////////////////////////////////////// initialization

function scene_changed_callback(){
  // create a timer to periodically update planet location
  // inbetween server syncronizations
  clear_entity_timers();
  add_entity_timer('planet_movement', 2000, function(){
    // TODO tracked_planet
    for(var planet in $tracked_planets){
      planet = $tracked_planets[planet];
      planet.move();
      $scene.animate();
    }
  });
}

$(document).ready(function(){ 
  $timers = {};
  $entity_registered_callbacks = [];

  on_session_validated(get_user_entities);
  on_scene_change(scene_changed_callback);

  /////////////////////// add handlers to server side tracker callbacks

  add_method_handler('motel::on_movement', function(loc){
    var entity = $tracker.matching_entities({location : loc.id});
    entity[0].update({location : loc});
    $scene.animate();
  });

  add_method_handler('manufactured::event_occurred', function(p0, p1, p2, p3){
    var evnt = p0;
    if(evnt == "resource_collected"){
      var ship = p1; var resource_source = p2; var quantity = p3;
      $tracker.add(ship);

    }else if(evnt == "mining_stopped"){
      var reason = p1; var ship = p2;
      // XXX hack serverside ship.mining might not be nil at this point
      ship.mining  = null;
      $tracker.add(ship);

    }else if(evnt == "attacked"){
      var attacker = p1; var defender = p2;
      attacker.attacking = defender;
      $tracker.add(attacker); $tracker.add(defender);

    }else if(evnt == "attacked_stop"){
      var attacker = p1; var defender = p2;
      attacker.attacking = null;
      $tracker.add(attacker); $tracker.add(defender);
      

    }else if(evnt == "defended"){
      var attacker = p1; var defender = p2;
      attacker.attacking = defender;
      $tracker.add(attacker); $tracker.add(defender);

    }else if(evnt == "defended_stop"){
      var attacker = p1;
      var defender = p2;
      attacker.attacking = null;
      $tracker.add(attacker); $tracker.add(defender);

    }else if(evnt == "destroyed"){
      var attacker = p1;
      var defender = p2;
      attacker.attacking = null;
      $tracker.add(attacker); $tracker.add(defender);
      $scene.remove(defender.id);

    }
  });


  /////////////////////// specific entities container controls
  // FIXME selected_entity may have changed in the meantime

  $('#ship_trigger_jg').live('click', function(e){
    trigger_jump_gate($selected_entity);
  });

  $('#ship_select_move').live('click', function(e){
    select_ship_destination($selected_entity);
  });

  $('#ship_move_to').live('click', function(e){
    omega_move_ship_to($selected_entity, $('#dest_x').attr('value'),
                                         $('#dest_y').attr('value'),
                                         $('#dest_z').attr('value'));
  });

  $('#ship_select_target').live('click', function(e){
    select_ship_target($selected_entity);
  });

  $('.ship_launch_attack').live('click', function(e){
    omega_ship_launch_attack($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_select_dock').live('click', function(e){
    ship_select_dock($selected_entity);
  });

  $('.ship_dock_at').live('click', function(e){
    omega_ship_dock_at($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_undock').live('click', function(e){
    omega_ship_undock($selected_entity);
  });

  $('#ship_select_transfer').live('click', function(e){
    ship_select_transfer($selected_entity);
  });

  $('.ship_transfer').live('click', function(e){
    omega_ship_transfer($selected_entity, $(e.currentTarget).html());
  });

  $('#ship_select_mine').live('click', function(e){
    ship_select_mining($selected_entity);
  });

  $('.ship_start_mining').live('click', function(e){
    var rsid = e.currentTarget.id.replace('start_mining_rs_', '');
    omega_ship_start_mining($selected_entity, rsid);
  });

  $('#station_select_construction').live('click', function(e){
    omega_station_construct($selected_entity);
  });
});
