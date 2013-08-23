/* Omega Javascript Entities
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "vendor/three"
//= require "vendor/helvetiker_font/helvetiker_regular.typeface"

/////////////////////////////////////////////////////////////////////

/* Entity registry, track all entities in the system
 *
 * Implements singleton pattern
 */
function Entities(){
  if ( Entities._singletonInstance )
    return Entities._singletonInstance;
  var _this = {};
  Entities._singletonInstance = _this;

  $.extend(_this, new Registry());

  /* Get/set node used to retrieve entities below
   */
  _this.node = function(new_node){
    if(new_node != null) _this._node = new_node;
    return _this._node;
  }

  return _this;
}

/////////////////////////////////////////////////////////////////////

/* Base Entity Class.
 *
 * Subclasses should define 'json_class' attribute
 */
function Entity(args){
  $.extend(this, new EventTracker());

  // copy all args to local attributes
  // http://api.jquery.com/jQuery.extend/
  this.update = function(args){
    for(var a in args){
      var arg = args[a];
      if($.inArray(a, this.ignore_properties) == -1)
        this[a] = arg;
    }
    this.raise_event('updated', this);
  }
  this.update(args);

  // return new copy of this
  this.clone = function(){
    return $.extend(true, {}, this);
  }

  /* Scene callbacks
   */
  this.added_to      = function(scene){}
  this.removed_from  = function(scene){}
  this.clicked_in    = function(scene){}
  this.unselected_in = function(scene){}

  /* add properties to ignore in json conversion
   */
  this.ignore_properties = ['toJSON', 'json_class', 'ignore_properties',
                            'added_to', 'removed_from', 'callbacks',
                            'clicked_in', 'unselected_in', 'update',
                            'raise_event', 'clone', 'on',
                            'clear_callbacks'];

  /* Convert entity to json respresentation
   */
  this.toJSON = function(){
    return new JRObject(this.json_class, this, this.ignore_properties).toJSON();
  };
}

/////////////////////////////////////////////////////////////////////

/* Omega User
 */
function User(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Users::User';

  /* Return bool indicating if the current user
   * is the anonymous user
   */
  this.is_anon = function(){
    return this.id == $omega_config['anon_user'];
  }
}

User.anon_user =
  new User({ id : $omega_config.anon_user,
             password : $omega_config.anon_pass });

/////////////////////////////////////////////////////////////////////

/* Omega Location
 */
function Location(args){
  $.extend(this, new Entity(args));
  this.json_class = 'Motel::Location';

  this.ignore_properties.push('movement_strategy');

  /* Return distance location is from the specified x,y,z
   * coordinates
   */
  this.distance_from = function(x, y, z){
    return Math.sqrt(Math.pow(this.x - x, 2) +
                     Math.pow(this.y - y, 2) +
                     Math.pow(this.z - z, 2));
  };

  /* Return boolean indicating if location is less than the
   * specified distance from the specified location
   */
  this.is_within = function(distance, loc){
    if(this.parent_id != loc.parent_id)
      return false
    return  this.distance_from(loc.x, loc.y, loc.z) < distance;
  };

  /* Convert location to short, human readable string
   */
  this.to_s = function(){
    return roundTo(this.x, 2) + "/" +
           roundTo(this.y, 2) + "/" +
           roundTo(this.z, 2);
  }
}

/////////////////////////////////////////////////////////////////////

/* Omega Galaxy
 */
function Galaxy(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Cosmos::Entities::Galaxy';
  this.background = 'galaxy' + this.background;

  /* override update to update all children instead of overwriting
   */
  this.old_update = this.update;
  this.update = function(oargs){
    var args = $.extend({}, oargs); // copy args

    if(args.location && this.location){
      this.location.update(args.location);
      delete args.location;
    }
    // assuming that system list is not variable
    if(args.solar_systems && this.solar_systems){
      for(var s in args.solar_systems)
        this.solar_systems[s].update(args.solar_systems[s]);
      delete args.solar_systems
    }
    this.old_update(args);
  }

  // convert children
  this.location = new Location(this.location);
  this.solar_systems = [];
  for(var sys in this.children)
    this.solar_systems[sys] = new SolarSystem(this.children[sys]);

  this.children = function(){
    return this.solar_systems;
  }
}

/* Return galaxy with the specified id
 */
Galaxy.with_id = function(id, cb){
  Entities().node().web_request('cosmos::get_entity', 'with_id', id, function(res){
    if(res.result){
      var gal = new Galaxy(res.result);
      cb.apply(null, [gal]);
    }
  });
}

/////////////////////////////////////////////////////////////////////

/* Omega SolarSystem
 */
function SolarSystem(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Cosmos::Entities::SolarSystem';
  var system = this;
  this.background = 'system' + this.background;

  /* Get first star
   */
  this.star = function() { return this.stars[0]; }

  /* override update to update all children instead of overwriting
   */
  this.old_update = this.update;
  this.update = function(oargs){
    var args = $.extend({}, oargs); // copy args

    if(args.location && this.location){
      this.location.update(args.location);
      delete args.location;
    }
    if(args.stars && this.stars){
      for(var s in args.stars)
        this.stars[s].update(args.stars[s]);
      delete args.stars;
    }
    // assuming that planets/asteroids/jump gates lists are not variable
    // (though individual properties such as location may be)
    if(args.planets && this.planets){
      for(var p in args.planets)
        this.planets[p].update(args.planets[p]);
      delete args.planets
    }
    if(args.asteroids && this.asteroids){
      for(var a in args.asteroids)
        this.asteroids[a].update(args.asteroids[a]);
      delete args.asteroids
    }
    if(args.jump_gates && this.jump_gates){
      for(var j in args.jump_gates)
        this.jump_gates[j].update(args.jump_gates[j]);
      delete args.jump_gates
    }

    // do not update components
    if(args.components) delete args.components;

    this.old_update(args);
  }

  // initialize missing children
  if(!this.stars)      this.stars      = [];
  if(!this.planets)    this.planets    = [];
  if(!this.asteroids)  this.asteroids  = [];
  if(!this.jump_gates) this.jump_gates = [];

  // convert children
  this.location = new Location(this.location);
  for(var c in this.children){
    if(this.children[c].json_class == 'Cosmos::Entities::Star')
      this.stars.push(new Star(this.children[c]))
    else if(this.children[c].json_class == 'Cosmos::Entities::Planet')
      this.planets.push(new Planet(this.children[c]))
    else if(this.children[c].json_class == 'Cosmos::Entities::Asteroid')
      this.asteroids.push(new Asteroid(this.children[c]))
    else if(this.children[c].json_class == 'Cosmos::Entities::JumpGate')
      this.jump_gates.push(new JumpGate(this.children[c]))
  }

  // adding jump gates lines is defered to later when we
  // can remotely retrieve endpoint systems
  this.add_jump_gate = function(jg, endpoint){
    var line_geometry =
      UIResources().cached("jump_gate_" + this.name + "-" + endpoint.name + "_line_geometry",
        function(i) {
          var geometry = new THREE.Geometry();
          geometry.vertices.push(new THREE.Vector3(system.location.x,
                                                   system.location.y,
                                                   system.location.z));

          geometry.vertices.push(new THREE.Vector3(endpoint.location.x,
                                                   endpoint.location.y,
                                                   endpoint.location.z));
          return geometry;
      });

    var line_material =
      UIResources().cached("jump_gate_line_material",
        function(i) {
          return new THREE.LineBasicMaterial({color: 0xFFFFFF});
      });

    var line =
      UIResources().cached("jump_gate_" + this.name + "-" + endpoint.name + "_line",
        function(i) {
          return new THREE.Line(line_geometry, line_material);
      });

    this.components.push(line);

    // if current scene is set, reload
    if(this.current_scene) this.current_scene.reload_entity(this);
  }

  // instantiate sphere to represent system on canvas
  var sphere_geometry =
    UIResources().cached('solar_system_sphere_geometry',
      function(i) {
        var radius   = 100, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_material =
    UIResources().cached("solar_system_sphere_material",
      function(i) {
        return new THREE.MeshBasicMaterial({color: 0xABABAB,
                                            opacity: 0.1,
                                            transparent: true});
      });

  var sphere =
    UIResources().cached("solar_system_" + this.id + "_sphere",
      function(i) {
        var sphere   = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = system.location.x;
        sphere.position.y = system.location.y;
        sphere.position.z = system.location.z ;
        return sphere;
      });

  this.clickable_obj = sphere;
  this.components.push(sphere);

  // instantiate plane to draw system image on canvas
  var plane_geometry =
    UIResources().cached('solar_system_plane_geometry',
      function(i) {
        return new THREE.PlaneGeometry(100, 100);
      });

  var plane_texture =
    UIResources().cached("solar_system_plane_texture",
      function(i) {
        var path = UIResources().images_path +
                   $omega_config.resources['solar_system']['material'];
        return UIResources().load_texture(path);
      });

  var plane_material =
    UIResources().cached("solar_system_plane_material",
      function(i) {
        var mat = new THREE.MeshBasicMaterial({map: plane_texture,
                                               alphaTest: 0.5});
        mat.side = THREE.DoubleSide;
        return mat;
      });

  var plane =
    UIResources().cached("solar_system_" + this.id + "_plane_mesh",
      function(i) {
        var plane = new THREE.Mesh(plane_geometry, plane_material);
        plane.position.x = system.location.x;
        plane.position.y = system.location.y;
        plane.position.z = system.location.z;

        plane.rotation.x = -0.5;
        return plane;
      });

  this.components.push(plane);

  // instantiate text to draw system name to canvas
  var text3d =
    UIResources().cached("solar_system_" + this.id + "label_geometry",
      function(i) {
        return new THREE.TextGeometry( system.name, {height: 12, width: 5, curveSegments: 2, font: 'helvetiker', size: 48});
      });

  var text_material =
    UIResources().cached("solar_system_text_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } );
      });

  var text =
    UIResources().cached("solar_system_" + this.id + "label",
      function(i) {
        var text = new THREE.Mesh( text3d, text_material );
        text.position.x = system.location.x;
        text.position.y = system.location.y;
        text.position.z = system.location.z + 50;
        return text;
      });

  this.components.push(text);


  /* Return solar systems children
   */
  this.children = function(){
    var entities = Entities().select(function(e){
      return e.system_id  == system.id &&
            (e.json_class  == "Manufactured::Ship" ||
             e.json_class  == "Manufactured::Station" )
   });

    return this.stars.concat(this.planets).
                      concat(this.asteroids).
                      concat(this.jump_gates).
                      concat(entities);
  }

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
}

/* Return solar system with the specified id
 */
SolarSystem.with_id = function(id, cb){
  Entities().node().web_request('cosmos::get_entity', 'with_id', id, function(res){
    if(res.result){
      var sys = new SolarSystem(res.result);
      cb.apply(null, [sys])
    }
  });
}

/* Return entities under solar system with the specified id
 */
SolarSystem.entities_under = function(id, cb){
  Entities().node().web_request('manufactured::get_entities', 'under', id, function(res){
    if(res.result){
      var cbv = [];
      for(var e in res.result){
        var entity = res.result[e];
        if(entity.json_class == "Manufactured::Ship")
          entity = new Ship(entity);
        else if(entity.json_class == "Manufactured::Station")
          entity = new Station(entity);
        else
          entity = null;

        if(entity != null)
          cbv.push(entity);
      }
      cb.apply(null, [cbv]);
    }
  });
}

/////////////////////////////////////////////////////////////////////

/* Omega Star
 */
function Star(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Cosmos::Entities::Star';
  var star = this;

  this.location = new Location(this.location);

  // instantiate sphere to draw star with on canvas
  var sphere_geometry =
    UIResources().cached('star_sphere_' + this.size + '_geometry',
      function(i) {
        var radius = star.size/5, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_texture =
    UIResources().cached("star_sphere_texture",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['star']['material'];
        return UIResources().load_texture(path);
      });

  var sphere_material =
    UIResources().cached("star_sphere_" + this.color + "_material",
      function(i) {
        return new THREE.MeshBasicMaterial({//color: parseInt('0x' + star.color),
                                            map: sphere_texture,
                                            overdraw : true});
      });

  var sphere =
    UIResources().cached("star_" + this.id + "_sphere_geometry",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = star.location.x;
        sphere.position.y = star.location.y;
        sphere.position.z = star.location.z;

        return sphere;
      });

  star.clickable_obj = sphere;
  this.components.push(sphere);
}

/////////////////////////////////////////////////////////////////////

/* Omega Planet
 */
function Planet(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Cosmos::Entities::Planet';
  var planet = this;

  this.location = new Location(this.location);

  /* override update
   */
  this.old_update = this.update;
  this.update = function(oargs){
    var args = $.extend({}, oargs); // copy args

    if(args.location && this.location){
      this.location.update(args.location);

      if(this.sphere){
        this.sphere.position.x = this.location.x;
        this.sphere.position.y = this.location.y;
        this.sphere.position.z = this.location.z;
      }

      for(var m in this.moons){
        var moon = this.moons[m];
        var ms   = this.moon_spheres[m];
        if(ms){
          ms.position.x = this.location.x + moon.location.x;
          ms.position.y = this.location.y + moon.location.y;
          ms.position.z = this.location.z + moon.location.z;
        }
      }

      delete args.location;
    }

    this.old_update(args);
  }

  // instantiate sphere to draw planet with on canvas
  var sphere_geometry =
    UIResources().cached('planet_sphere_' + this.size + '_geometry',
      function(i) {
        var radius = planet.size, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  // generate mesh texture from color mapping
  var ti = parseInt('0x' + this.color) % 5;

  var sphere_texture =
    UIResources().cached("planet_"+ti+"_sphere_texture",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['planet'+ti]['material'];
        return UIResources().load_texture(path);
      });

  var sphere_material =
    UIResources().cached("planet_sphere_" + planet.color + "_material",
      function(i) {
        return new THREE.MeshBasicMaterial({map: sphere_texture});
      });

  this.sphere =
    UIResources().cached("planet_" + this.id + "_sphere_geometry",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = planet.location.x;
        sphere.position.y = planet.location.y;
        sphere.position.z = planet.location.z;
        return sphere;
      });

  this.clickable_obj = sphere;
  this.components.push(this.sphere);

  // calculate the planet's orbit
  this.orbit =
    UIResources().cached("planet_" + this.id + "_orbit",
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
    UIResources().cached("planet_" + this.id + "_orbit_geometry",
      function(i) {
        var geometry = new THREE.Geometry();
        var first = null, last = null;
        for(var o in planet.orbit){
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
    UIResources().cached("planet_" + this.id + "_orbit_line",
      function(i) {
        return new THREE.Line(orbit_geometry, orbit_material);
      });

  this.components.push(orbit_line);

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


  this.moon_spheres = [];
  for(var m in this.moons){
    var moon = this.moons[m];
    var sphere =
      UIResources().cached("moon_"+ moon.id +"sphere",
                           function(i) {
                             var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
                             sphere.position.x = planet.location.x + moon.location.x;
                             sphere.position.y = planet.location.y + moon.location.y;
                             sphere.position.z = planet.location.z + moon.location.z;
                             return sphere;
                           });
    this.components.push(sphere);
    this.moon_spheres.push(sphere);
  }
}

/////////////////////////////////////////////////////////////////////

/* Omega Asteroid
 */
function Asteroid(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Cosmos::Entities::Asteroid';
  var asteroid = this;

  this.location = new Location(this.location);

  // instantiate mesh to draw asteroid on canvas
  this.create_mesh = function(){
    if(this.mesh_geometry == null) return;
    var mesh =
      UIResources().cached("asteroid_" + this.id + "_mesh",
        function(i) {
          var mesh = new THREE.Mesh(asteroid.mesh_geometry, asteroid.mesh_material);
          mesh.position.x = asteroid.location.x;
          mesh.position.y = asteroid.location.y;
          mesh.position.z = asteroid.location.z;

          var scale = $omega_config.resources['asteroid'].scale;
          if(scale){
            mesh.scale.x = scale[0];
            mesh.scale.y = scale[1];
            mesh.scale.z = scale[2];
          }

          return mesh;
        });

    this.clickable_obj = mesh;
    this.components.push(mesh);

    // reload asteroid if already in scene
    if(this.current_scene) this.current_scene.reload_entity(this);
  }

  this.mesh_material =
    UIResources().cached("asteroid_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { color: 0x666600, wireframe: false });
      });

  this.mesh_geometry =
    UIResources().cached('asteroid_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['asteroid']['geometry'];
        UIResources().load_geometry(path, function(geo){
          asteroid.mesh_geometry = geo;
          UIResources().set('asteroid_geometry', asteroid.mesh_geometry);
          asteroid.create_mesh();
        })
        return null;
      });

  this.create_mesh();

  // some text to render in details box on click
  this.details = function(){
    return ['Asteroid: ' + this.name + "<br/>",
            '@ ' + this.location.to_s() + '<br/>'];
  }

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
}

/////////////////////////////////////////////////////////////////////

/* Omega Jump Gate
 */
function JumpGate(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  //this.id = this.solar_system + '-' + this.endpoint;

  this.json_class = 'Cosmos::Entities::JumpGate';
  var jg = this;

  this.location = new Location(this.location);

  // instantiate mesh to draw gate on canvas
  this.create_mesh = function(){
    if(this.mesh_geometry == null) return;
    this.mesh =
      UIResources().cached("jump_gate_" + this.id + "_mesh",
        function(i) {
          var mesh = new THREE.Mesh(jg.mesh_geometry, jg.mesh_material);
          mesh.position.x = jg.location.x;
          mesh.position.y = jg.location.y;
          mesh.position.z = jg.location.z;

          var offset = $omega_config.resources['jump_gate'].offset;
          if(offset){
            mesh.position.x += offset[0];
            mesh.position.y += offset[1];
            mesh.position.z += offset[2];
          }

          var scale = $omega_config.resources['jump_gate'].scale;
          if(scale){
            mesh.scale.x = scale[0];
            mesh.scale.y = scale[1];
            mesh.scale.z = scale[2];
          }

          var rotation = $omega_config.resources['jump_gate'].rotation;
          if(rotation){
            mesh.rotation.x = rotation[0];
            mesh.rotation.y = rotation[1];
            mesh.rotation.z = rotation[2];
            mesh.matrix.setRotationFromEuler(mesh.rotation);
          }

          return mesh;
        });

    this.clickable_obj = this.mesh;
    this.components.push(this.mesh);

    // reload entity if already in scene
    if(this.current_scene) this.current_scene.reload_entity(this);
  }

  var mesh_texture =
    UIResources().cached("jump_gate_mesh_texture",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['jump_gate']['material'];
        var texture = UIResources().load_texture(path);
        texture.wrapS  = THREE.RepeatWrapping;
        texture.wrapT  = THREE.RepeatWrapping;
        texture.repeat.x  = 5;
        texture.repeat.y  = 5;
        return texture;
      });

  this.mesh_material =
    UIResources().cached("jump_gate_mesh_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { map: mesh_texture } );
      });

  this.mesh_geometry =
    UIResources().cached('jump_gate_mesh_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['jump_gate']['geometry'];
        UIResources().load_geometry(path, function(geometry){
          jg.mesh_geometry = geometry;
          UIResources().set('jump_gate_mesh_geometry', geometry);
          jg.create_mesh();
        })
        return null;
      });

  this.create_mesh();

  // instantiate sphere to draw around jump_gate on canvas
  var sphere_geometry =
    UIResources().cached('jump_gate_' + this.trigger_distance + '_container_geometry',
      function(i) {
        var radius    = this.trigger_distance, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_material =
    UIResources().cached("jump_gate_container_material",
      function(i) {
        return new THREE.MeshBasicMaterial({color: 0xffffff,
                                            transparent: true,
                                            opacity: 0.4});

      });

  this.sphere =
    UIResources().cached("jump_gate_" + this.id + "_container",
                         function(i) {
                           var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
                           sphere.position.x = jg.location.x;
                           sphere.position.y = jg.location.y;
                           sphere.position.z = jg.location.z;
                           sphere.scale.x = sphere.scale.y = sphere.scale.z = 5;
                           return sphere;
                         });

  // some text to render in details box on click
  this.details = function(){
    return ['Jump Gate to ' + this.endpoint_id + '<br/>',
            '@ ' + this.location.to_s() + "<br/><br/>",
            "<span class='commands' id='cmd_trigger_jg'>Trigger</div>"];
  }

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = function(scene){
    this.selected = true;

    $('#cmd_trigger_jg').die();
    $('#cmd_trigger_jg').live('click', function(e){
      Commands.trigger_jump_gate(jg);
    });

    if(this.components.indexOf(this.sphere) == -1)
      this.components.push(this.sphere);
    this.clickable_obj = this.sphere;
    scene.reload_entity(this);
  }

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    this.selected = false;

    scene.reload_entity(this, function(s,e){
      var si = e.components.indexOf(e.sphere);
      if(si != -1) e.components.splice(si, 1);
      e.clickable_obj = e.mesh;
    });
  }

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;

  }

}

/////////////////////////////////////////////////////////////////////

/* Omega Ship
 */
function Ship(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Manufactured::Ship';
  var ship = this;

  this.location = new Location(this.location);

  /* helper to lookup mining target in local registry
   *
   * (needs to be defined before update is called)
   */
  this.resolve_mining_target = function(mining_target){
    var sys  = Entities().get(this.system_id);
    var asts = sys ? sys.asteroids : [];
    for(var a in asts){
      if(asts[a].id == mining_target.entity_id){
        this.mining = mining_target;
        this.mining.entity = asts[a];
        break;
      }
    }
  }

  /* override update
   */
  this.old_update = this.update;
  this.update = function(oargs){
    var args = $.extend({}, oargs); // copy args

    if(args.location && this.location){
      this.location.update(args.location);

      if(this.mesh){
        this.mesh.position.x = this.location.x;
        this.mesh.position.y = this.location.y;
        this.mesh.position.z = this.location.z;

        this.set_orientation(this.mesh)
      }

      if(this.attack_line){
        this.attack_line_geo.vertices[0].x = this.location.x;
        this.attack_line_geo.vertices[0].y = this.location.y;
        this.attack_line_geo.vertices[0].z = this.location.z;
      }

      if(this.mining_line){
        this.mining_line_geo.vertices[0].x = this.location.x;
        this.mining_line_geo.vertices[0].y = this.location.y;
        this.mining_line_geo.vertices[0].z = this.location.z;
      }

      delete args.location;

    }

    var to_remove = [];

    // handle attack state changes
    if(args.attacking){
      if(this.attack_line){
        if(this.components.indexOf(this.attack_line) == -1)
          this.components.push(this.attack_line);

        this.attack_line_geo.vertices[1].x = args.attacking.location.x;
        this.attack_line_geo.vertices[1].y = args.attacking.location.y;
        this.attack_line_geo.vertices[1].z = args.attacking.location.z;
      }
    }else if(this.attacking && this.attack_line){
      to_remove.push(this.attack_line)
    }

    // handle mining state changes
    if(args.mining){
      this.resolve_mining_target(args.mining);

      if(this.mining_line){
        if(this.components.indexOf(this.mining_line) == -1)
          this.components.push(this.mining_line);

        this.mining_line_geo.vertices[1].x = this.mining.entity.location.x;
        this.mining_line_geo.vertices[1].y = this.mining.entity.location.y;
        this.mining_line_geo.vertices[1].z = this.mining.entity.location.z;
      }

    }else if(this.mining && this.mining_line){
      to_remove.push(this.mining_line);
    }

    if(this.current_scene) this.current_scene.reload_entity(this, function(s, e){
      for(var r in to_remove)
        e.components.splice(e.components.indexOf(to_remove[r]), 1);
    });

    // do not update components from args
    if(args.components) delete args.components;

    this.old_update(args);
  }

  // XXX run new update method
  // (a bit redunant w/ update invoked in Entity constructor)
  this.update(args);

  this.belongs_to_user = function(user){
    return this.user_id == user;
  }
  this.belongs_to_current_user = function(){
    return Session.current_session != null &&
           this.belongs_to_user(Session.current_session.user_id);
  }

  /* helper to set orientation
   */
  this.set_orientation = function(mesh){
    // apply base mesh rotation
    var rotation = $omega_config.resources[this.type].rotation
    mesh.rotation.x = mesh.rotation.y = mesh.rotation.z = 0;
    if(rotation){
      mesh.rotation.x = rotation[0];
      mesh.rotation.y = rotation[1];
      mesh.rotation.z = rotation[2];
    }
    mesh.matrix.setRotationFromEuler(mesh.rotation);

    // set location orientation
    var oax = cp(0, 0, 1, this.location.orientation_x,
                          this.location.orientation_y,
                          this.location.orientation_z);
    var oab = abwn(0, 0, 1, this.location.orientation_x,
                            this.location.orientation_y,
                            this.location.orientation_z);

    // XXX edge case if facing straight back to preserve 'top'
    // TODO expand this to cover all cases where oab > 1.57 or < -1.57
    if(Math.abs(oab - Math.PI) < 0.0001) oax = [0,1,0];
    var orm = new THREE.Matrix4().makeRotationAxis({x:oax[0], y:oax[1], z:oax[2]}, oab);
    orm.multiplySelf(mesh.matrix);
    mesh.rotation.setEulerFromRotationMatrix(orm);
  }

  // instantiate mesh to draw ship on canvas
  this.create_mesh = function(){
    if(this.mesh_geometry == null) return;
    this.mesh =
      UIResources().cached("ship_" + this.id + "_mesh",
        function(i) {
          var mesh = new THREE.Mesh(ship.mesh_geometry, ship.mesh_material);
          mesh.position.x = ship.location.x;
          mesh.position.y = ship.location.y;
          mesh.position.z = ship.location.z;

          var scale = $omega_config.resources[ship.type].scale;
          if(scale){
            mesh.scale.x = scale[0];
            mesh.scale.y = scale[1];
            mesh.scale.z = scale[2];
          }

          ship.set_orientation(mesh);
          return mesh;
        });

    if(this.hp > 0){
      this.clickable_obj = this.mesh;
      this.components.push(this.mesh);
    }

    // reload entity if already in scene
    if(this.current_scene) this.current_scene.reload_entity(this);
  }

  this.mesh_material =
    UIResources().cached("ship_"+this.type+"_mesh_material",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[ship.type]['material'];
        var t = UIResources().load_texture(path);
        return new THREE.MeshBasicMaterial({map: t, overdraw: true});
      });

  this.mesh_geometry =
    UIResources().cached('ship_'+this.type+'_mesh_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[ship.type]['geometry'];
        UIResources().load_geometry(path, function(geo){
          ship.mesh_geometry = geo;
          UIResources().set('ship_'+this.type+'_mesh_geometry', ship.mesh_geometry)
          ship.create_mesh();
        })
        return null;
      });

  this.create_mesh();

  // setup attack vector
  var line_material =
    UIResources().cached('ship_attacking_material',
      function(i) {
        return new THREE.LineBasicMaterial({color: 0xFF0000 })

      });

  this.attack_line_geo =
    UIResources().cached('ship_'+this.id+'_attacking_geometry',
                         function(i) {
                           var geometry = new THREE.Geometry();
                           var av = ship.attacking ?
                                    ship.attacking.location : {x:0, y:0, z:0};
                           geometry.vertices.push(new THREE.Vector3(ship.location.x,
                                                                    ship.location.y,
                                                                    ship.location.z));
                           geometry.vertices.push(new THREE.Vector3(av[0], av[1], av[2]));

                           return geometry;
                         });
  this.attack_line =
    UIResources().cached('ship_'+this.id+'_attacking_line',
                         function(i) {
                           var line = new THREE.Line(ship.attack_line_geo, line_material);
                           return line;
                         });

  var line_material =
    UIResources().cached('ship_mining_material',
      function(i) {
        return new THREE.LineBasicMaterial({color: 0x0000FF});
      });

  this.mining_line_geo =
    UIResources().cached('ship_'+this.id+'_mining_geometry',
                         function(i) {
                           var geometry = new THREE.Geometry();
                           var av = ship.mining && ship.mining.entity ?
                                    ship.mining.entity.location : {x:0, y:0, z:0};
                           geometry.vertices.push(new THREE.Vector3(ship.location.x,
                                                                    ship.location.y,
                                                                    ship.location.z));
                           geometry.vertices.push(new THREE.Vector3(av[0], av[1], av[2]));

                           return geometry;
                         });
  this.mining_line =
    UIResources().cached('ship_'+this.id+'_mining_line',
                         function(i) {
                           var line = new THREE.Line(ship.mining_line_geo, line_material);
                           return line;
                         });


  // draw attack vector if attacking
  if(this.attacking)
    this.components.push(this.attack_line);

  // draw mining vector if mining
  else if(this.mining)
    this.components.push(this.mining_line);

  // some text to render in details box on click
  this.details = function(){
    var details = ['Ship: ' + this.id + '<br/>',
                   '@ ' + this.location.to_s() + '<br/>',
                   "Resources: <br/>"];
    for(var r in this.resources){
      var res = this.resources[r];
      details.push(res.quantity + " of " + res.material_id + "<br/>")
    }

    if(this.belongs_to_current_user()){
      details.push("<span id='cmd_move_select' class='commands'>move</span>");
      details.push("<span id='cmd_attack_select' class='commands'>attack</span>");
      var dcss = this.docked_at ? 'display: none' : '';
      var ucss = this.docked_at ? '' : 'display: none';
      details.push("<span id='cmd_dock_select' class='commands' style='" + dcss + "'>dock</span>");
      details.push("<span id='cmd_undock' class='commands' style='" + ucss + "'>undock</span>");
      details.push("<span id='cmd_transfer' class='commands' style='" + ucss + "'>transfer</span>");
      details.push("<span id='cmd_mine_select' class='commands'>mine</span>");
    }

    return details;
  }

  // text to render in popup on selection command click
  this.selection =
    { 'cmd_move_select' :
        ['Move Ship',
         function(){
          // coordinate specification
          return "<div class='dialog_row'>" + this.id + "</div>" +
                 "<div class='dialog_row'>X: <input id='dest_x' type='text' value='"+roundTo(this.location.x,2)+"'/></div>" +
                 "<div class='dialog_row'>Y: <input id='dest_y' type='text' value='"+roundTo(this.location.y,2)+"'/></div>" +
                 "<div class='dialog_row'>Z: <input id='dest_z' type='text' value='"+roundTo(this.location.z,2)+"'/></div>" +
                 "<div class='dialog_row'><input type='button' value='move' id='cmd_move' /></div>";
         }] ,

      'cmd_attack_select' :
        ['Launch Attack',
         function(){
          // load attack target selection from ships in the vicinity
          var entities = Entities().select(function(e) {
            return e.json_class == 'Manufactured::Ship'            &&
                   e.user_id    != Session.current_session.user_id &&
                   e.hp > 0 &&
                   e.location.is_within(ship.attack_distance, ship.location);
          });

          var text = "Select " + this.id + " target<br/>";
          for(var e in entities){
            var entity = entities[e];
            text += '<span id="cmd_attack_'+entity.id+'" class="cmd_attack dialog_cmds">' + entity.id + '</span>';
          }
          return text;
        }],

      'cmd_dock_select' :
        ['Dock Ship',
         function(){
          // load dock target selection from stations in the vicinity
          var entities = Entities().select(function(e) {
            return e.json_class == 'Manufactured::Station' &&
                   e.belongs_to_current_user() &&
                   e.location.is_within(100, ship.location);
          });

          var text = 'Dock ' + this.id + ' at<br/>';
          for(var e in entities){
            var entity = entities[e];
            text += '<span id="cmd_dock_' + entity.id + '" class="cmd_dock dialog_cmds">' + entity.id + '</span>';
          }
          return text;
        }],

      'cmd_mine_select' :
        ['Start Mining',
         function(){
          return "Select resource to mine with "+ ship.id +" <br/>";
        }]
    };

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = function(scene){
    // remove existing command page element handlers
    // XXX should be exact same selectors as w/ live handlers below:
    $('#cmd_move_select,#cmd_attack_select,' +
      '#cmd_dock_select,#cmd_mine_select').die();
    $('#cmd_move').die()
    $('.cmd_attack').die()
    $('.cmd_dock').die();
    $('#cmd_undock').die();
    $('#cmd_transfer').die();
    $('.cmd_mine').die();

    // wire up selection command page elements,
    $('#cmd_move_select,#cmd_attack_select,' +
      '#cmd_dock_select,#cmd_mine_select').
        live('click', function(e){
          // just raise the corresponding event w/ content to display,
          // up to another component to take this and render it
          var cmd     = e.target.id;
          var cmds    = ship.selection[cmd];
          var title   = cmds[0];
          var content = cmds[1].apply(ship)
          ship.raise_event(cmd, ship, title, content);
        });

    // wire up command page elements
    $('#cmd_move').live('click', function(e){
      Commands.move_ship(ship,
                         $('#dest_x').val(),
                         $('#dest_y').val(),
                         $('#dest_z').val(),
                         function(res){
                           ship.raise_event('cmd_move', ship);
                         });
    })

    $('.cmd_attack').live('click', function(e){
      var eid = e.currentTarget.id.substr(11);
      var entity = Entities().get(eid);
      Commands.launch_attack(ship, entity,
                             function(res){
                               ship.raise_event('cmd_attack', ship, entity);
                             });
    })

    $('.cmd_dock').live('click', function(e){
      var eid = e.currentTarget.id.substr(9);
      var entity = Entities().get(eid);
      Commands.dock_ship(ship, entity,
                         function(res){
                           ship.update(res.result)
                           ship.raise_event('cmd_dock', ship, entity)
                         });
      $('#cmd_dock_select').hide();
      $('#cmd_undock').show();
      $('#cmd_transfer').show();
    })

    $('#cmd_undock').live('click', function(e){
      Commands.undock_ship(ship,
                           function(res){
                             ship.update(res.result)
                             ship.raise_event('cmd_undock', ship);
                           });
      $('#cmd_dock_select').show();
      $('#cmd_undock').hide();
      $('#cmd_transfer').hide();
    })

    $('#cmd_transfer').live('click', function(e){
      Commands.transfer_resources(ship, ship.docked_at.id,
                                  function(res){
                                    if(!res.error){
                                      var sh = res.result[0];
                                      var st = res.result[1];
                                      ship.raise_event('cmd_transfer', sh, st);
                                    }
                                  });
    })

    $('.cmd_mine').live('click', function(e){
      var rsid = e.currentTarget.id.substr(9);
      Commands.start_mining(ship, rsid,
                            function(res){
                              ship.raise_event('cmd_mine', ship, rsid);
                            });
    })

    // change color
    this.selected = true;

    // reload ship in scene
    scene.reload_entity(this);
  }

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    this.selected = false;
    scene.reload_entity(this);
  }

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }
}

/* Return ship w/ the specified id
 */
Ship.with_id = function(id, cb){
  Entities().node().web_request('manufactured::get_entity', 'with_id', id, function(res){
    if(res.result){
      var ship = new Ship(res.result);
      cb.apply(null, [ship]);
    }
  });
};

/* Return ships owned by the specified user
 */
Ship.owned_by = function(user_id, cb){
  Entities().node().web_request('manufactured::get_entities',
                                'of_type', 'Manufactured::Ship',
                                'owned_by', user_id, function(res){
    if(res.result){
      var ships = [];
      for(var e in res.result){
        ships.push(new Ship(res.result[e]));
      }
      cb.apply(null, [ships])
    }
  });
}

/////////////////////////////////////////////////////////////////////

/* Omega Station
 */
function Station(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Manufactured::Station';
  var station = this;

  this.location = new Location(this.location);

  this.belongs_to_user = function(user){
    return this.user_id == user;
  }
  this.belongs_to_current_user = function(){
    return Session.current_session != null &&
           this.belongs_to_user(Session.current_session.user_id);
  }

  /* override update
   */
  this.old_update = this.update;
  this.update = function(oargs){
    var args = $.extend({}, oargs); // copy args

    if(args.location && this.location){
      this.location.update(args.location);
      delete args.location;
    }

    // do not update components from args
    if(args.components) delete args.components;

    this.old_update(args);
  }

  // instantiate mesh to draw station on canvas
  this.create_mesh = function(){
    if(this.mesh_geometry == null) return;

    this.mesh =
      UIResources().cached("station_" + this.id + "_mesh",
        function(i) {
          var mesh = new THREE.Mesh(station.mesh_geometry, station.mesh_material);
          mesh.position.x = station.location.x;
          mesh.position.y = station.location.y;
          mesh.position.z = station.location.z;
          mesh.rotation.x = mesh.rotation.y = mesh.rotation.z = 0;
          mesh.scale.x = mesh.scale.y = mesh.scale.z = 5;
          return mesh;
        });

    this.clickable_obj = this.mesh;
    this.components.push(this.mesh);

    // reload station if already in scene
    if(this.current_scene) this.current_scene.reload_entity(this);
  }

  this.mesh_material =
    UIResources().cached("station_"+station.type +"_material",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[station.type]['material'];
        var t = UIResources().load_texture(path);
        return new THREE.MeshBasicMaterial({map: t, overdraw: true});
    });

  var mesh_geometry =
    UIResources().cached('station_'+station.type+'_mesh_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources[station.type]['geometry'];
        UIResources().load_geometry(path, function(geo){
          station.mesh_geometry = geo;
          UIResources().set('station_'+station.type+'_mesh_geometry', station.mesh_geometry);
          station.create_mesh();
        });
        return null;
    });

  this.create_mesh();

  // some text to render in details box on click
  this.details = function(){
    var details = ['Station: ' + this.id + '<br/>',
                   '@ ' + this.location.to_s() + '<br/>',
                   "Resources: <br/>"];
    for(var r in this.resources){
      var res = this.resources[r];
      details.push(res.quantity + " of " + res.material_id + "<br/>")
    }

    if(this.belongs_to_current_user())
      details.push("<span id='cmd_construct' class='commands'>construct</span>");
    return details;
  }

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = function(scene){
    $('#cmd_construct').die();
    $('#cmd_construct').live('click', function(e){
      Commands.construct_entity(station,
                                function(res){
                                  if(res.error) ; // TODO
                                  else
                                    station.raise_event('cmd_construct',
                                                        new Ship(res.result[1]));
                                });
    });

    this.selected = true;
    scene.reload_entity(this);
  }

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    this.selected = false;
    scene.reload_entity(this);
  }

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }
}

/* Return stations owned by the specified user
 */
Station.owned_by = function(user_id, cb){
  Entities().node().web_request('manufactured::get_entities',
                                'of_type', 'Manufactured::Station',
                                'owned_by', user_id, function(res){
    if(res.result){
      var stations = [];
      for(var e in res.result){
        stations.push(new Station(res.result[e]));
      }
      cb.apply(null, [stations])
    }
  });
}

/////////////////////////////////////////////////////////////////////

/* Omega Mission
 */
function Mission(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Missions::Mission'

  this.assign_cmd = '<span id="'+this.id+'" class="assign_mission">assign</span>';

  /* Return time which this mission expires
   */
  this.expires = function(){
    // XXX create parsable date
    var d = new Date(Date.parse(this.assigned_time.replace(/-/g, '/').slice(0, 19)));
    d.setSeconds(d.getSeconds() + this.timeout);
    return d;
  }

  /* Return boolean indicating if this mission is expired
   */
  this.expired = function(){
    return (this.assigned_time != null) && (this.expires() < new Date());
  }

  /* Return boolean indicating if mission is assigned to the specified user
   */
  this.assigned_to_user = function(user_id){
    return this.assigned_to_id == user_id;
  }

  /* Return boolean indicating if mission is assigned to the current user
   */
  this.assigned_to_current_user = function(){
    return Session.current_session != null &&
           this.assigned_to_user(Session.current_session.user_id);
  }
}

/* Return all missions
 */
Mission.all = function(cb){
  Entities().node().web_request('missions::get_missions',
                                function(res){
    var missions = [];
    if(res.result)
      for(var m in res.result)
        missions.push(new Mission(res.result[m]));
    cb.apply(null, [missions]);
  });
}

/////////////////////////////////////////////////////////////////////

/* Omega StatResult
 */
function Statistic(args){
  $.extend(this, new Entity(args));

  this.json_class = 'Stats::StatResult'
}

/* Return specified stat
 */
Statistic.with_id = function(id, args, cb){
  Entities().node().web_request('stats::get', id, args,
                                function(res){
    if(res.result){
      var stat = new Statistic(res.result);
      cb.apply(null, [stat]);
    }
  });
}
