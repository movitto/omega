/* Omega Entity Tracker
 *
 * Copyright (C) 2012 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/////////////////////////////////////// Helper Methods

/* Round number to specified number of places
 */
function roundTo(number, places){
  return Math.round(number * Math.pow(10,places)) / Math.pow(10,places);
}

/* Encapsulate result returned from server in its corresponding
 * client object class
 */
function convert_entity(entity){
  if(entity.json_class == "Motel::Location"){
    entity = new OmegaLocation(entity);

  }else if(entity.json_class == "Cosmos::Galaxy"){
    entity.location = convert_entity(entity.location);
    for(var solar_system in entity.solar_systems)
      entity.solar_systems[solar_system] = convert_entity(entity.solar_systems[solar_system]);
    entity = new OmegaGalaxy(entity);

  }else if(entity.json_class == "Cosmos::SolarSystem"){
    entity.location = convert_entity(entity.location);
    entity.star = convert_entity(entity.star);
    for(var planet in entity.planets)
      entity.planets[planet] = convert_entity(entity.planets[planet]);
    for(var asteroid in entity.asteroids)
      entity.asteroids[asteroid] = convert_entity(entity.asteroids[asteroid]);
    for(var jump_gate in entity.jump_gates)
      entity.jump_gates[jump_gate] = convert_entity(entity.jump_gates[jump_gate]);

    entity = new OmegaSolarSystem(entity);

  }else if(entity.json_class == "Cosmos::Star"){
    entity.location = convert_entity(entity.location);
    entity = new OmegaStar(entity);

  }else if(entity.json_class == "Cosmos::Planet"){
    entity.location = convert_entity(entity.location);
    for(var moon in entity.moons)
      entity.moons[moon] = convert_entity(entity.moons[moon]);

    entity = new OmegaPlanet(entity);

  }else if(entity.json_class == "Cosmos::Asteroid"){
    entity.location = convert_entity(entity.location);
    entity = new OmegaAsteroid(entity);

  }else if(entity.json_class == "Cosmos::JumpGate"){
    entity.location = convert_entity(entity.location);
    entity = new OmegaJumpGate(entity);

  }else if(entity.json_class == "Manufactured::Ship"){
    entity.location = convert_entity(entity.location);
    entity = new OmegaShip(entity);

  }else if(entity.json_class == "Manufactured::Station"){
    entity.location = convert_entity(entity.location);
    entity = new OmegaStation(entity);

  }else if(entity.json_class == "Users::Session"){
    entity.user = convert_entity(entity.user);

  }else if(entity.json_class == "Users::User"){
    entity = new OmegaUser(entity);

  }

  $omega_registry.add(entity);

  return entity;
}

/////////////////////////////////////// Omega Timer

/* Initialize new Omega Timer
 */
function OmegaTimer(time, callback){
  /////////////////////////////////////// private data

  var timer  = $.timer(callback);

  /////////////////////////////////////// public methods

  /* Stop internal timer */
  this.stop = function(){
    timer.stop();
  }

  /////////////////////////////////////// initialization

  timer.set({time : time, autostart : true });
}


/////////////////////////////////////// Omega Registry

/* Initialize new Omega Registry
 */
function OmegaRegistry(){
  /////////////////////////////////////// private data

  var registry               = {};

  var timers                 = {};

  var selected_entities      = [];

  var registration_callbacks = [];

  /////////////////////////////////////// public methods
  
  /* Register method to be invoked whenever a entity is
   * registered with the tracker
   */
  this.on_registration = function(callback){
    registration_callbacks.push(callback);
  }

  /* Adds entity to registry
   */
  this.add = function(entity){
    // XXX hacks
    if(!entity.id && entity.name)
      entity.id = entity.name;
    else if(entity.json_class == "Cosmos::JumpGate")
      entity.id = entity.solar_system + "-" + entity.endpoint;

    //this.entities[entity_id].update(entity); if existing ?
    registry[entity.id] = entity;

    for(var cb in registration_callbacks)
      registration_callbacks[cb](entity);

    // TODO ?
    // if($selected_entity && $selected_entity.id == this.id)
    //  $selected_entity.clicked();
  }

  /* Return entity w/ specified id
   */
  this.get = function(entity_id){
    return registry[entity_id];
  }

  /* Return entities matching specified criteria.
   * Filters should be an array of callbacks to invoke with
   * each entity, all of which must return true for an entity
   * to include it in the return results.
   */
  this.select = function(filters){
    var ret = [];

    for(var entity in registry){
      entity = registry[entity];
      var matched = true;
      for(var filter in filters){
        filter = filters[filter];
        if(!filter(entity)){
          matched = false;
          break;
        }
      }

      if(matched)
        ret.push(entity);
    }

    return ret;
  }

  /* Retrieve and store local copy of server side entity
   * Takes method to perform retrieval and method to invoke w/
   * entity when found
   */
  this.cached = function(entity_id, retrieval, retrieved){
    if(registry[entity_id] != null && retrieved != null){
      retrieved(registry[entity_id]);
    }

    retrieval(entity_id, retrieved);
    return null;
  }

  /* Add new timer to registry
   */
  this.add_timer = function(id, time, callback){
    timers[id] = new OmegaTimer(time, callback);
  }

  /* Clear all timers
   */
  this.clear_timers = function(){
    for(var timer in timers){
      timers[timer].stop();
      delete timers[timer];
    }
    timers = [];
  }
}

/////////////////////////////////////// Omega Entity

/* Initialize new Omega Entity
 */
function OmegaEntity(entity){

  // XXX had to mark the private data and methods below
  //     as public for things to work properly

  /////////////////////////////////////// private data

  // scene properties
  this.clickable_obj     = null;

  this.scene_objs        = [];

  // copy all attributes from entity to self
  for(var attr in entity)
    this[attr] = entity[attr];

  /////////////////////////////////////// private methods

  // callbacks (should be set in subclasses)

  this.on_load           = null;

  this.on_clicked        = null;

  /////////////////////////////////////// public methods

  this.load = function(){
    if(this.on_load) this.on_load();
  }

  this.clicked = function(){
    if(this.on_clicked) this.on_clicked();
  }

  this.is_a = function(type){
    return this.json_class == type;
  };

  this.belongs_to_user = function(user_id){
    return this.user_id == user_id;
  };

}

//OmegaEntity.prototype.__noSuchMethod__ = function(id, args) {
//  this.apply(id, args);
//}

/////////////////////////////////////// Omega Location

/* Initialize new Omega Location
 */
function OmegaLocation(loc){

  $.extend(this, new OmegaEntity(loc));

  /////////////////////////////////////// public methods

  this.distance_from = function(x, y, z){
    return Math.sqrt(Math.pow(this.x - x, 2) +
                     Math.pow(this.y - y, 2) +
                     Math.pow(this.z - z, 2));
  };

  this.is_within = function(distance, loc){
    if(this.parent_id != loc.parent_id)
      return false 
    return  this.distance_from(loc.x, loc.y, loc.z) < distance;
  };

  this.to_s = function(){
    return roundTo(this.x, 2) + "/" +
           roundTo(this.y, 2) + "/" +
           roundTo(this.z, 2);
  }

  this.toJSON = function(){
    return new JRObject("Motel::Location", this,
       ["toJSON", "json_class", "entity", "movement_strategy", "notifications",
        "movement_callbacks", "proximity_callbacks"]).toJSON();
  };

  this.clone = function(){
    var nloc = { x                 : this.x ,
                 y                 : this.y ,
                 z                 : this.z,
                 parent_id         : this.parent_id,
                 movement_strategy : this.movement_strategy };

    return new OmegaLocation(nloc);
  };

}

/////////////////////////////////////// Omega Galaxy

/* Initialize new Omega Galaxy
 */
function OmegaGalaxy(galaxy){

  $.extend(this, new OmegaEntity(galaxy));

  /////////////////////////////////////// public methods

  this.children = function(){
    return this.solar_systems;
  }

}

OmegaGalaxy.cached = function(name, retrieved){
  var retrieval = function(name, retrieved){
    OmegaQuery.galaxy_with_name(name, retrieved);
  };
  $omega_registry.cached(name, retrieval, retrieved);
}

/////////////////////////////////////// Omega SolarSystem

/* Initialize new Omega SolarSystem
 */
function OmegaSolarSystem(system){

  $.extend(this, new OmegaEntity(system));

  /////////////////////////////////////// public methods

  this.children = function(){
    var system   = this;
    var ships    = $omega_registry.select([function(e){ return e.system_name == system.name &&
                                                               e.json_class  == "Manufactured::Ship" }]);
    var stations = $omega_registry.select([function(e){ return e.system_name == system.name &&
                                                               e.json_class  == "Manufactured::Station" }]);

    return [this.star].
            concat(this.planets).
            concat(this.asteroids).
            concat(this.jump_gates).
            concat(ships).
            concat(stations);
  }

  /////////////////////////////////////// private methods

  this.on_load = function(){
    //for(var j=0; j<this.jump_gates.length;++j){
    //  var jg = this.jump_gates[j];
    //  var endpoint = $tracker.load(jg.endpoint);

    //  var geometry = new THREE.Geometry();
    //  geometry.vertices.push(new THREE.Vector3(this.location.x,
    //                                           this.location.y,
    //                                           this.location.z));

    //  geometry.vertices.push(new THREE.Vector3(endpoint.x, endpoint.y, endpoint.z));
    //  var line = new THREE.Line(geometry, $omega_scene.materials['line']);
    //  this.scene_objs.push(line);
    //  $omega_scene.add(line);
    //}
    
    // draw sphere representing system
    var radius = system.size, segments = 32, rings = 32;
    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), $omega_scene.materials['system']);
    sphere.position.x = this.location.x;
    sphere.position.y = this.location.y;
    sphere.position.z = this.location.z ;
    this.clickable_obj = sphere;
    this.scene_objs.push(sphere);
    $omega_scene.add(sphere);

    // draw label
    var text3d = new THREE.TextGeometry( system.name, {height: 10, width: 3, curveSegments: 2, font: 'helvetiker', size: 16});
    var text = new THREE.Mesh( text3d, $omega_scene.materials['system_label'] );
    text.position.x = this.location.x - 50;
    text.position.y = this.location.y - 50;
    text.position.z = this.location.z - 50;
    text.lookAt($omega_camera.position());
    this.scene_objs.push(text);
    $omega_scene.add(text);
  }

  this.on_clicked = function(){
    $omega_scene.set_root($omega_registry.get(this.id));
  }
}

OmegaSolarSystem.cached = function(name, retrieved){
  var retrieval = function(name, retrieved){
    OmegaQuery.system_with_name(name, retrieved);
  };
  $omega_registry.cached(name, retrieval, retrieved);
}


/////////////////////////////////////// Omega Star

/* Initialize new Omega Star
 */
function OmegaStar(star){

  $.extend(this, new OmegaEntity(star));

  /////////////////////////////////////// private methods

  this.on_load = function(){
    var radius = this.size, segments = 32, rings = 32;

    if($omega_scene.materials['star' + this.color] == null)
      $omega_scene.materials['star' + this.color] =
        new THREE.MeshLambertMaterial({color: parseInt('0x' + this.color),
                                       blending: THREE.AdditiveBlending })

    var sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings),
                                $omega_scene.materials['star' + this.color]);

    sphere.position.x = this.location.x ;
    sphere.position.y = this.location.y ;
    sphere.position.z = this.location.z ;

    this.clickable_obj = sphere;
    this.scene_objs.push(sphere);
    $omega_scene.add(sphere);
  }
}

/////////////////////////////////////// Omega Planet

/* Initialize new Omega Planet
 */
function OmegaPlanet(planet){

  $.extend(this, new OmegaEntity(planet));

  /////////////////////////////////////// public methods

  this.children = function(){
    return this.moons;
  }

  /////////////////////////////////////// private methods

  this.on_load = function(){
    // draw sphere representing planet
    var radius = this.size, segments = 32, rings = 32;
    if($omega_scene.geometries['planet' + radius] == null)
       $omega_scene.geometries['planet' + radius] =
         new THREE.SphereGeometry(radius, segments, rings);
    if($omega_scene.materials['planet' + this.color] == null)
       $omega_scene.materials['planet' + this.color] =
         new THREE.MeshLambertMaterial({color: parseInt('0x' + this.color),
                                        blending: THREE.AdditiveBlending});

    var sphere = new THREE.Mesh($omega_scene.geometries['planet' + radius],
                                $omega_scene.materials[ 'planet' + this.color]);

    sphere.position.x = this.location.x;
    sphere.position.y = this.location.y;
    sphere.position.z = this.location.z;

    this.clickable_obj = sphere;
    this.scene_objs.push(sphere);
    $omega_scene.add(sphere);

    // draw orbit
    this.calc_orbit();
    var geometry = new THREE.Geometry();
    for(var o in this.orbit){
      if(o != 0 & (o % 10 == 0)){
        var orbit  = this.orbit[o];
        var porbit = this.orbit[o-1];
        geometry.vertices.push(new THREE.Vector3(orbit[0],  orbit[1],  orbit[2]));
        geometry.vertices.push(new THREE.Vector3(porbit[0], porbit[1], porbit[2]));
      }
    }
    var line = new THREE.Line(geometry, $omega_scene.materials['orbit']);
    this.scene_objs.push(line);
    this.scene_objs.push(geometry);
    // !FIXME! rendering orbits results in a big performance hit,
    // need to figure out a better way and/or make this togglable
    $omega_scene.add(line);
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    // draw moons
    for(var m=0; m<this.moons.length; ++m){
      var moon = this.moons[m];
      var sphere = new THREE.Mesh($omega_scene.geometries['moon'],
                                  $omega_scene.materials['moon']);

      sphere.position.x = this.location.x + moon.location.x;
      sphere.position.y = this.location.y + moon.location.y;
      sphere.position.z = this.location.z + moon.location.z;

      moon.scene_obj = sphere;
      this.scene_objs.push(sphere);
      $omega_scene.add(sphere);
    }

    // retrack planet movement
    $omega_node.ws_request('motel::remove_callbacks', this.location.id,      null);
    $omega_node.ws_request('motel::track_movement',   this.location.id, 120, null);
  }

  this.calc_orbit = function(){
    this.orbit = [];

    // intercepts
    var a = this.location.movement_strategy.semi_latus_rectum /
              (1 - Math.pow(this.location.movement_strategy.eccentricity, 2));

    var b = Math.sqrt(this.location.movement_strategy.semi_latus_rectum * a);

    // linear eccentricity
    var le = Math.sqrt(Math.pow(a, 2) - Math.pow(b, 2));

    // center (assumes planet's location's movement_strategy.relative to is set to foci
    var cx = -1 * this.location.movement_strategy.direction_major_x * le;
    var cy = -1 * this.location.movement_strategy.direction_major_y * le;
    var cz = -1 * this.location.movement_strategy.direction_major_z * le;

    // orbit
    this.orbiti = 0;
    for(var i = 0; i < 2 * Math.PI; i += (Math.PI / 180)){
      var ox = cx + a * Math.cos(i) * this.location.movement_strategy.direction_major_x +
                    b * Math.sin(i) * this.location.movement_strategy.direction_minor_x ;

      var oy = cy + a * Math.cos(i) * this.location.movement_strategy.direction_major_y +
                    b * Math.sin(i) * this.location.movement_strategy.direction_minor_y ;

      var oz = cz + a * Math.cos(i) * this.location.movement_strategy.direction_major_z +
                    b * Math.sin(i) * this.location.movement_strategy.direction_minor_z ;

      var absi = parseInt(i * 180 / Math.PI);

      if(absi == 0 ||
         this.location.distance_from(ox, oy, oz) <
         this.location.distance_from(this.orbit[absi-1][0],
                                     this.orbit[absi-1][1],
                                     this.orbit[absi-1][2]))
          this.orbiti = absi;
      this.orbit.push([ox, oy, oz]);
    }
  }

  var move = function(){
    var now = (new Date()).getTime() / 1000;

    if(this.last_moved == null){
      this.last_moved = now;
      return;
    }

    var elapsed     = now - this.last_moved;
    var distance    = this.location.movement_strategy.speed * elapsed;
    this.last_moved = now;

    var absd     = parseInt(distance * 180 / Math.PI);
    this.orbiti += absd;
    if(this.orbiti > 360) this.orbiti -= 360;

    var nloc        = this.orbit[this.orbiti];
    this.location.x = nloc[0];
    this.location.y = nloc[1];
    this.location.z = nloc[2];

    // updated_planet
    var di = this.distance_from.apply(this,
                                      this.orbit[this.orbiti]);

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
}


/////////////////////////////////////// Omega Asteroid

/* Initialize new Omega Asteroid
 */
function OmegaAsteroid(asteroid){

  $.extend(this, new OmegaEntity(asteroid));

  /////////////////////////////////////// private methods

  this.on_load = function(){
    var text = new THREE.Mesh($omega_scene.geometries['asteroid'],
                              $omega_scene.materials['asteroid']   );

    text.position.x = this.location.x;
    text.position.y = this.location.y;
    text.position.z = this.location.z;

    this.clickable_obj = text;
    this.scene_objs.push(text);
    $omega_scene.add(text);
  }

  this.on_clicked = function(){
    var details = ['Asteroid: ' + this.name + "<br/>",
                   '@ ' + this.location.to_s() + '<br/>',
                   'Resources: <br/>'];
    $omega_entity_container.show(details);

    $omega_node.web_request('cosmos::get_resource_sources', this.name,
      function(resource_sources, error){
        if(error == null){
          var details = [];
          for(var r in resource_sources){
            var res = resource_sources[r];
            details.push(res.quantity + " of " + res.resource.name + " (" + res.resource.type + ")<br/>");
          }
          $omega_entity_container.append(details);
        }
      });
  }
}

/////////////////////////////////////// Omega JumpGate

/* Initialize new Omega JumpGate
 */
function OmegaJumpGate(jump_gate){

  $.extend(this, new OmegaEntity(jump_gate));

  /////////////////////////////////////// private methods

  this.on_load = function(){
    var geometry = new THREE.PlaneGeometry( 50, 50 );
    var material = $omega_scene.materials['jump_gate']
    var mesh     = new THREE.Mesh(geometry, material);

    mesh.position.set( this.location.x, this.location.y, this.location.z );
    this.scene_objs.push(mesh);
    this.scene_objs.push(geometry);
    $omega_scene.add( mesh );

    // sphere to draw around jump gate when selected
    var radius    = this.trigger_distance, segments = 32, rings = 32;
    var sgeometry = new THREE.SphereGeometry(radius, segments, rings);
    var smaterial = $omega_scene.materials['jump_gate_selected'];
    var ssphere   = new THREE.Mesh(sgeometry, smaterial);
                                 
    ssphere.position.x = this.location.x ;
    ssphere.position.y = this.location.y ;
    ssphere.position.z = this.location.z ;
    this.scene_objs.push(ssphere);

    if(this.selected){
      $omega_scene.add(ssphere);
      this.clickable_obj = ssphere;
    }else{
      this.clickable_obj = mesh;
    }
  }

  var on_unselected = function(){
    $selected_entity.selected = false;
    $omega_scene.reload($selected_entity);
    $selected_entity = null;
    $omega_entity_container.on_closed(null);
  }

  this.on_clicked = function(){
    var details = ['Jump Gate to ' + this.endpoint + '<br/>',
                   '@ ' + this.location.to_s() + "<br/><br/>",
                   "<div class='cmd_icon' id='ship_trigger_jg'>Trigger</div>"];
    $omega_entity_container.show(details);

    $selected_entity = this;
    this.selected = true;
    $omega_scene.reload(this);

    $omega_entity_container.on_closed(on_unselected);
  }

}


/////////////////////////////////////// Omega Ship

/* Initialize new Omega Ship
 */
function OmegaShip(ship){

  $.extend(this, new OmegaEntity(ship));

  /////////////////////////////////////// private methods

  this.on_load = function(){
    // do not load if ship is destroyed
    if(this.hp <= 0) return;

    // draw crosshairs representing ship
    var color = '0x';
    if(this.selected)
      color += "FFFF00";
    else if(this.docked_at)
      color += "99FFFF";
    else if(!this.belongs_to_user($user_id))
      color += "CC0000";
    else
      color += "00CC00";

    if($omega_scene.materials['ship' + color] == null)
       $omega_scene.materials['ship' + color] =
         new THREE.LineBasicMaterial({color: parseInt(color)});

    var material = $omega_scene.materials['ship' + color]

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(this.location.x - this.size/2,
                                             this.location.y,
                                             this.location.z));
    geometry.vertices.push(new THREE.Vector3(this.location.x + this.size/2,
                                             this.location.y,
                                             this.location.z));

    var line = new THREE.Line(geometry, material);
    this.scene_objs.push(line);
    this.scene_objs.push(geometry);
    $omega_scene.add(line);

    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(this.location.x,
                                             this.location.y - this.size/2,
                                             this.location.z));
    geometry.vertices.push(new THREE.Vector3(this.location.x,
                                             this.location.y + this.size/2,
                                             this.location.z));

    line = new THREE.Line(geometry, material);
    this.scene_objs.push(line);
    this.scene_objs.push(geometry);
    $omega_scene.add(line);

    geometry = new THREE.PlaneGeometry( ship.size, ship.size );
    material = $omega_scene.materials['ship_surface']

    //var texture = new THREE.MeshFaceMaterial();
    var mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(this.location.x, this.location.y, this.location.z);
    this.scene_objs.push(mesh);
    this.scene_objs.push(geometry);
    $omega_scene.add(mesh);

    this.clickable_obj = mesh;

    // if ship is attacking another, draw line of attack
    if(this.attacking){
      material = $omega_scene.materials['ship_attacking'];
      geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(this.location.x,
                                               this.location.y,
                                               this.location.z));
      geometry.vertices.push(new THREE.Vector3(this.attacking.location.x,
                                               this.attacking.location.y + 25,
                                               this.attacking.location.z));

      line = new THREE.Line(geometry, material);
      this.scene_objs.push(line);
      this.scene_objs.push(geometry);
      $omega_scene.add(line);
    }

    // if ship is mining, draw line to mining target
    if(this.mining){
      material = $omega_scene.materials['ship_mining']
      geometry = new THREE.Geometry();
      geometry.vertices.push(new THREE.Vector3(this.location.x,
                                               this.location.y,
                                               this.location.z));
      geometry.vertices.push(new THREE.Vector3(this.mining.entity.location.x,
                                               this.mining.entity.location.y + 25,
                                               this.mining.entity.location.z));

      line = new THREE.Line(geometry, material);
      this.scene_objs.push(line);
      this.scene_objs.push(geometry);
      $omega_scene.add(line);
    }

    // remove & resetup callbacks
    $omega_node.ws_request('motel::remove_callbacks',        this.location.id,                       null);
    $omega_node.ws_request('manufactured::remove_callbacks', this.id,                                null);
    $omega_node.ws_request('motel::track_movement',          this.location.id, 20,                   null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'resource_collected', null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'mining_stopped',     null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'attacked',           null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'attacked_stop',      null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'defended',           null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'defended_stop',      null);
    $omega_node.ws_request('manufactured::subscribe_to',     this.id,          'destroyed',          null);
  }

  var on_unselected = function(){
    $selected_entity.selected = false;
    $omega_scene.reload($selected_entity);
    $selected_entity = null;
    $omega_entity_container.on_closed(null);
  }

  this.on_clicked = function(){
    var rstxt = 'Resources: <br/>';
    for(var r in this.resources){
      rstxt += this.resources[r] + " of " + r + ", ";
    }

    var details = ['Ship: ' + this.id +"<br/>",
                   '@ ' + this.location.to_s() + '<br/>',
                   rstxt];

    if(this.belongs_to_user($user_id)){
      details.push("<div class='cmd_icon' id='ship_select_move'>move</div>"); // TODO only if not mining / attacking
      details.push("<div class='cmd_icon' id='ship_select_target'>attack</div>");
      details.push("<div class='cmd_icon' id='ship_select_dock'>dock</div>");
      details.push("<div class='cmd_icon' id='ship_undock'>undock</div>");
      details.push("<div class='cmd_icon' id='ship_select_transfer'>transfer</div>");
      details.push("<div class='cmd_icon' id='ship_select_mine'>mine</div>");
    }

    $omega_entity_container.show(details);

    if(!this.docked_at){
      $('#ship_select_dock').show();
      $('#ship_undock').hide();
      $('#ship_select_transfer').hide();
    }else{
      $('#ship_select_dock').hide();
      $('#ship_undock').show();
      $('#ship_select_transfer').show();
    }

    $selected_entity = this;
    this.selected = true;
    $omega_entity_container.on_closed(on_unselected);
    $omega_scene.reload(this);
  }

}

/////////////////////////////////////// Omega Station

/* Initialize new Omega Station
 */
function OmegaStation(station){

  $.extend(this, new OmegaEntity(station));

  /////////////////////////////////////// private methods

  this.on_load = function(){
    var color = '0x';
    if(this.selected)
      color += "FFFF00";
    else if(!this.belongs_to_user($user_id))
      color += "CC0011";
    else
      color += "0000CC";

    if($omega_scene.materials['station' + color] == null)
      $omega_scene.materials['station' + color] =
        new THREE.LineBasicMaterial({color: parseInt(color)});
    var material = $omega_scene.materials['station'+color];

    var geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(this.location.x - this.size/2,
                                             this.location.y,
                                             this.location.z));
    geometry.vertices.push(new THREE.Vector3(this.location.x + this.size/2,
                                             this.location.y,
                                             this.location.z));

    var line = new THREE.Line(geometry, material);
    this.scene_objs.push(line);
    $omega_scene.add(line);

    geometry = new THREE.Geometry();
    geometry.vertices.push(new THREE.Vector3(this.location.x,
                                             this.location.y - this.size/2,
                                             this.location.z));
    geometry.vertices.push(new THREE.Vector3(this.location.x,
                                             this.location.y + this.size/2,
                                             this.location.z));

    line = new THREE.Line(geometry, material);
    this.scene_objs.push(line);
    this.scene_objs.push(geometry);
    $omega_scene.add(line);

    material = $omega_scene.materials['station_surface'];
    geometry = new THREE.PlaneGeometry( station.size, station.size );

    var mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(this.location.x,
                      this.location.y,
                      this.location.z);
    this.scene_objs.push(mesh);
    this.scene_objs.push(geometry);
    $omega_scene.add(mesh);

    this.clickable_obj = mesh;
  }

  var on_unselected = function(){
    $selected_entity.selected = false;
    $omega_scene.reload($selected_entity);
    $selected_entity = null;
    $omega_entity_container.on_closed(null);
  }

  this.on_clicked = function(){
    var rstxt = 'Resources: <br/>';
    for(var r in this.resources){
      rstxt += this.resources[r] + " of " + r + ", ";
    }

    var details = ['Station: ' + this.id + "<br/>",
                   '@' + this.location.to_s() + '<br/>',
                   rstxt];

    if(this.belongs_to_user($user_id)){
      details.push("<div class='cmd_icon' id='station_select_construction'>construct</div>");
    }

    $omega_entity_container.show(details);

    $selected_entity = this;
    this.selected = true;
    $omega_entity_container.on_closed(on_unselected)
    $omega_scene.reload(this);
  }
}

/////////////////////////////////////// initialization

$(document).ready(function(){
  $omega_registry       = new OmegaRegistry();
});



/////////////// XXX TODO still need to relocate this stuff

$(document).ready(function(){
  $omega_session.on_session_validated(function(){
    OmegaQuery.entities_owned_by($user_id, function(entities){
      for(var entityI in entities){
        var entity = entities[entityI];
        OmegaSolarSystem.cached(entity.system_name, function(system){
          OmegaQuery.galaxy_with_name(system.galaxy_name);
          OmegaQuery.entities_under(system.name);
        });
      }
    });
  });

  $omega_scene.on_scene_change(function(){
    // create a timer to periodically update planet location
    // inbetween server syncronizations
    $omega_registry.clear_timers();
    $omega_registry.add_timer('planet_movement', 2000, function(){
      // TODO tracked_planet
      //for(var planet in $tracked_planets){
      //  planet = $tracked_planets[planet];
      //  planet.move();
      //  $omega_scene.animate();
      //}
    });
  });

  /////////////////////// add handlers to server side tracker callbacks

  $omega_node.add_request_handler('motel::on_movement', function(loc){
console.log("on movement");
    var entity = $omega_registry.select([function(e){ return e.location &&
                                                             e.location.id == loc.id }])[0];

    entity.location.x = loc.x;
    entity.location.y = loc.y;
    entity.location.z = loc.z;
    convert_entity(entity);

    // XXX hack if scene changed remove callbacks
    if($omega_scene.get_root().location.id != entity.location.parent_id){
      $omega_node.ws_request('motel::remove_callbacks', loc.id, null);

    }else{
      // FIXME just update scene_object locations, no need to
      // reload entire object
      $omega_scene.reload(entity);
    }
  });

  $omega_node.add_request_handler('manufactured::event_occurred', function(p0, p1, p2, p3){
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
      $omega_scene.remove(defender.id);

    }
  });
});
