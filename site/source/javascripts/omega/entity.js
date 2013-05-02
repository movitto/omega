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
  if ( arguments.callee._singletonInstance )
    return arguments.callee._singletonInstance;
  arguments.callee._singletonInstance = this;

  $.extend(this, new Registry());

  /* Get/set node used to retrieve entities below
   */
  this.node = function(new_node){
    if(new_node != null) this._node = new_node;
    return this._node;
  }

  return this;
}

/////////////////////////////////////////////////////////////////////

/* Base Entity Class.
 *
 * Subclasses should define 'json_class' attribute
 */
function Entity(args){
  $.extend(this, new EventTracker());

  // copy all args to local attributes
  this.update = function(args){
    $.extend(this, args);
    this.raise_event('updated', this);
  }
  this.update(args);

  // XXX hack but works
  if(this.id == null && this.name != null) this.id = this.name;

  /* Scene callbacks
   */
  this.added_to      = function(scene){}
  this.removed_from  = function(scene){}
  this.clicked_in    = function(scene){}
  this.unselected_in = function(scene){}

  /* add properties to ignore in json conversion
   */
  this.ignore_properties = [];
  this.ignore_properties.push('toJSON');
  this.ignore_properties.push('json_class');
  this.ignore_properties.push('ignore_properties');
  this.ignore_properties.push('callbacks');

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

  this.json_class = 'Cosmos::Galaxy';

  // store galaxies in the registry
  Entities().set(this.id, this);

  /* override update to update all children instead of overwriting
   */
  this.old_update = this.update;
  this.update = function(args){
    if(args.location && this.location){
      this.location.update(args.location);
      delete args.location;
    }
    // assuming that system list is not variable
    if(args.solar_systems && this.solar_systems){
      for(var s in args.solar_systems)
        this.solar_systems.update(args.solar_systems[s]);
      delete args.solar_systems
    }
    this.old_update(args);
  }

  // convert children
  this.location = new Location(this.location);
  for(var sys in this.solar_systems) this.solar_systems[sys] = new SolarSystem(this.solar_systems[sys])

  this.children = function(){
    return this.solar_systems;
  }
}

/* Return galaxy with the specified name
 */
Galaxy.with_name = function(name, cb){
  Entities().node().web_request('cosmos::get_entity', 'with_name', name, function(res){
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

  this.json_class = 'Cosmos::SolarSystem';
  var system = this;

  // store solar systems in the registry
  Entities().set(this.id, this);

  /* override update to update all children instead of overwriting
   */
  this.old_update = this.update;
  this.update = function(args){
    if(args.location && this.location){
      this.location.update(args.location);
      delete args.location;
    }
    if(args.star && this.star){
      this.star.update(args.star);
      delete args.star;
    }
    // assuming that planets/asteroids/jump gates lists are not variable
    // (though individual properties such as location may be)
    if(args.planets && this.planets){
      for(var p in args.planets)
        this.planets.update(args.planets[p]);
      delete args.planets
    }
    if(args.asteroids && this.asteroids){
      for(var a in args.asteroids)
        this.asteroids.update(args.asteroids[a]);
      delete args.asteroids
    }
    if(args.jump_gates && this.jump_gates){
      for(var j in args.jump_gates)
        this.jump_gates.update(args.jump_gates[j]);
      delete args.jump_gates
    }

    this.old_update(args);
  }

  // convert children
  this.location = new Location(this.location);
  this.star = new Star(this.star);
  for(var pl in this.planets) this.planets[pl] = new Planet(this.planets[pl])
  for(var ast in this.asteroids) this.asteroids[ast] = new Asteroid(this.asteroids[ast])
  for(var jg in this.jump_gates) this.jump_gates[jg] = new JumpGate(this.jump_gates[jg])

  // XXX adding jump gates lines is defered to later when we
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
      });

    var line_material =
      UIResources().cached("jump_gate_line_material",
        function(i) {
          return new THREE.MeshBasicMaterial({opacity: 0.0, transparent: true});
      });

    var line =
      UIResources().cached("jump_gate_" + this.name + "-" + endpoint.name + "_line",
        function(i) {
          return new THREE.Line(line_geometry, line_material);
      });

    this.components.push(line);
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
        return new THREE.MeshBasicMaterial({opacity: 0.0, transparent: true});
      });

  var sphere =
    UIResources().cached("solar_system_" + this.id + "_sphere",
      function(i) {
        var sphere   = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = system.location.x;
        sphere.position.y = system.location.y;
        sphere.position.z = system.location.z ;
        system.clickable_obj = sphere;
        return sphere;
      });

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
                           var path = UIResources().images_path + '/solar_system.png';
                           return UIResources().load_texture(path);
                         });

  var plane_material =
    UIResources().cached("solar_system_plane_material",
      function(i) {
        return new THREE.MeshBasicMaterial({map: plane_texture, alphaTest: 0.5});
      });

  var plane =
    UIResources().cached("solar_system_" + this.id + "_plane_geometry",
                         function(i) {
                           var plane = new THREE.Mesh(plane_geometry, plane_material);
                           plane.position.x = system.location.x;
                           plane.position.y = system.location.y;
                           plane.position.z = system.location.z;
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
        return new THREE.Mesh( text3d, text_material );
      });

  this.components.push(text);


  /* Return solar systems children
   */
  this.children = function(){
    var entities = Entities().select(function(e){
      return e.system_name  == system.name &&
            (e.json_class  == "Manufactured::Ship" ||
             e.json_class  == "Manufactured::Station" )
   });

    return [this.star].concat(this.planets).
                       concat(this.asteroids).
                       concat(this.jump_gates).
                       concat(entities);
  }

  /* added_to scene callback
   */
  this.added_to = function(scene){
    plane.lookAt(scene.camera.position());
  }

  /* clicked_in scene callback
   */
  this.clicked_in = function(scene){
    scene.set(this);
    //scene.animate();
  }
}

/* Return solar system with the specified name
 */
SolarSystem.with_name = function(name, cb){
  Entities().node().web_request('cosmos::get_entity', 'with_name', name, function(res){
    if(res.result){
      var sys = new SolarSystem(res.result);
      cb.apply(null, [sys])
    }
  });
}

/* Return entities under solar system with the specified name
 */
SolarSystem.entities_under = function(name, cb){
  Entities().node().web_request('manufactured::get_entities', 'under', name, function(res){
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

  this.json_class = 'Cosmos::Star';
  var star = this;

  this.location = new Location(this.location);

  // instantiate sphere to draw star with on canvas
  var sphere_geometry =
    UIResources().cached('star_sphere_' + this.size + '_geometry',
      function(i) {
        var radius = this.size/4, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_texture =
    UIResources().cached("star_sphere_texture",
      function(i) {
        var path = UIResources().images_path +
                      '/textures/greensun.jpg';
        return UIResources().load_texture(path);
      });

  var sphere_material =
    UIResources().cached("star_sphere_" + this.color + "_material",
      function(i) {
        return new THREE.MeshBasicMaterial({color: parseInt('0x' + star.color),
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
                           star.clickable_obj = sphere;
                           return sphere;
                         });

  this.components.push(sphere);
}

/////////////////////////////////////////////////////////////////////

/* Omega Planet
 */
function Planet(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Cosmos::Planet';
  var planet = this;

  this.location = new Location(this.location);

  /* override update
   */
  this.old_update = this.update;
  this.update = function(args){
    if(args.location && this.location){
      this.location.update(args.location);

      this.sphere.position.x = this.location.x;
      this.sphere.position.y = this.location.y;
      this.sphere.position.z = this.location.z;

      for(var m in this.moons){
        var moon = this.moons[m];
        var ms   = this.moon_spheres[m];
        ms.position.x = this.location.x + moon.location.x;
        ms.position.y = this.location.y + moon.location.y;
        ms.position.z = this.location.z + moon.location.z;
      }

      delete args.location;
    }

    this.old_update(args);
  }

  // instantiate sphere to draw planet with on canvas
  var sphere_geometry =
    UIResources().cached('planet_sphere_' + this.size + '_geometry',
      function(i) {
        var radius = this.size, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_material =
    UIResources().cached("planet_sphere_" + this.color + "_material",
      function(i) {
        return new THREE.MeshBasicMaterial({color: parseInt('0x' + this.color)});
      });

  this.sphere =
    UIResources().cached("planet_" + this.id + "_sphere_geometry",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = planet.location.x;
        sphere.position.y = planet.location.y;
        sphere.position.z = planet.location.z;
        planet.clickable_obj = sphere;
        return sphere;
      });

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


  var moon_spheres = [];
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
    moon_spheres.push(sphere);
  }
}

/////////////////////////////////////////////////////////////////////

/* Omega Asteroid
 */
function Asteroid(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  this.json_class = 'Cosmos::Asteroid';
  var asteroid = this;

  this.location = new Location(this.location);

  // instantiate mesh to draw asteroid on canvas
  var mesh_material =
    UIResources().cached("asteroid_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { color: 0x666600, wireframe: false });
      });

  // comments related to / around create_mesh and geometry also apply to JumpGate,Ship,Asteroid below
  var create_mesh = function(geometry){
    var mesh =
      UIResources().cached("asteroid_" + asteroid.id + "_mesh",
                           function(i) {
                             var mesh = new THREE.Mesh(geometry, mesh_material);
                             mesh.position.x = asteroid.location.x;
                             mesh.position.y = asteroid.location.y;
                             mesh.position.z = asteroid.location.z;
                             return mesh;
                           });

    asteroid.components.push(mesh);

    // reload asteroid if already in scene
    if(asteroid.current_scene) asteroid.current_scene.reload(asteroid);
  }

  var mesh_geometry =
    UIResources().cached('asteroid_geometry',
                         function(i) {
                           // will invoke callback when geometry is loaded
                           var path = UIResources().images_path + '/meshes/asteroids1.js';
                           // TODO race condition if multiple requests are invoked before first returns
                           //  (not biggest issue as geometry will be overwritten, but would be good to resolve)
                           UIResources().load_geometry(path, function(geometry){
                             UIResources().set('asteroid_geometry', geometry)
                             create_mesh(geometry);
                           })
                           return null;
                         });

  if(mesh_geometry != null) create_mesh(mesh_geometry);

  // instantiate sphere to draw around asteroid on canvas
  var sphere_geometry =
    UIResources().cached('asteroid_container_geometry',
      function(i) {
        var astradius = 25, astsegments = 32, astrings = 32;
        return new THREE.SphereGeometry(astradius, astsegments, astrings);
      });

  var sphere_material =
    UIResources().cached("asteroid_container_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { opacity: 0.0, transparent: true } );
      });

  var sphere =
    UIResources().cached("asteroid_" + this.id + "_container",
      function(i) {
        var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = asteroid.location.x;
        sphere.position.y = asteroid.location.y;
        sphere.position.z = asteroid.location.z;
        sphere.scale.x = sphere.scale.y = sphere.scale.z = 5;
        asteroid.clickable_obj = sphere;
        return sphere;
      });

  this.components.push(sphere);

  // some text to render in details box on click
  this.details = ['Asteroid: ' + this.name + "<br/>",
                  '@ ' + this.location.to_s() + '<br/>'];

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

  this.json_class = 'Cosmos::JumpGate';
  var jg = this;

  this.location = new Location(this.location);

  // instantiate mesh to draw jump gate on canvas
  var mesh_texture =
    UIResources().cached("jump_gate_mesh_texture",
      function(i) {
        var path = UIResources().images_path + '/textures/jump_gate.jpg';
        var texture = UIResources().load_texture(path);
        texture.wrapS  = THREE.RepeatWrapping;
        texture.wrapT  = THREE.RepeatWrapping;
        texture.repeat.x  = 5;
        texture.repeat.y  = 5;
        return texture;
      });

  var mesh_material =
    UIResources().cached("jump_gate_mesh_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { map: mesh_texture } );
      });

  // see comments related to / around create_mesh and geometry in Asteroid above
  var create_mesh = function(geometry){
    var mesh =
      UIResources().cached("jump_gate_" + jg.id + "_mesh",
        function(i) {
          var mesh = new THREE.Mesh(geometry, mesh_material);
          mesh.position.x = jg.location.x;
          mesh.position.y = jg.location.y;
          mesh.position.z = jg.location.z;
          return mesh;
        });

    jg.clickable_obj = mesh;
    jg.components.push(mesh);

    // reload entity if already in scene
    if(jg.current_scene) jg.current_scene.reload(jg);
  }

  var mesh_geometry =
    UIResources().cached('jump_gate_mesh_geometry',
      function(i) {
        var path = UIResources().images_path + '/meshes/jump_gate.js';
        UIResources().load_geometry(path, function(geometry){
          UIResources().set('jump_gate_mesh_geometry', geometry);
          create_mesh(geometry);
        })
        return null;
      });

  if(mesh_geometry != null) create_mesh(mesh_geometry);

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

  var sphere =
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
  this.details = ['Jump Gate to ' + this.endpoint + '<br/>',
                  '@ ' + this.location.to_s() + "<br/><br/>",
                  "<span class='command' id='cmd_trigger_jg'>Trigger</div>"];

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = function(scene){
    $('#cmd_trigger_jg').live('click', function(e){
      Commands.trigger_jump_gate(jg, function(j, entities){
        // remove entities from scene
        for(var e in entities)
          scene.remove_entity(entities[e]);

        jg.raise_event('cmd_trigger_jg', j, entities)
      });
    })

    this.components.push(sphere);
    this.clickable_obj = sphere;
    scene.reload_entity(this);
  }

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    $('#command_trigger_jg').die();

    this.components.splice(this.components.indexOf(sphere), 1);
    this.clickable_obj = mesh;
    scene.reload_entity(this);
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

  // store ships in the registry
  Entities().set(this.id, this);

  this.location = new Location(this.location);

  /* override update
   */
  this.old_update = this.update;
  this.update = function(args){
    if(args.location && this.location){
      this.location.update(args.location);

      this.mesh.position.x = this.location.x;
      this.mesh.position.y = this.location.y;
      this.mesh.position.z = this.location.z;

      this.mesh.rotation.x = this.location.orientation_x;
      this.mesh.rotation.y = this.location.orientation_y;
      this.mesh.rotation.z = this.location.orientation_z;

      this.sphere.position.x = this.location.x;
      this.sphere.position.y = this.location.y;
      this.sphere.position.z = this.location.z;

      this.attack_line_geo.vertices[0].x = this.location.x;
      this.attack_line_geo.vertices[0].y = this.location.y;
      this.attack_line_geo.vertices[0].z = this.location.z;

      this.mining_line_geo.vertices[0].x = this.location.x;
      this.mining_line_geo.vertices[0].y = this.location.y;
      this.mining_line_geo.vertices[0].z = this.location.z;

      // handle attack/mining state changes
      if(args.attacking && !this.attacking){
        this.components.push(this.attack_line);

      }else if(this.attacking && !args.attacking){
        this.components.splice(this.components.indexOf(this.attack_line), 1);
      }

      if(args.mining && !this.mining){
        this.components.push(this.mining_line);

      }else if(this.mining && !args.mining){
        this.components.splice(this.components.indexOf(this.mining_line), 1);
      }

      delete args.location;
    }

    this.old_update(args);
  }

  this.belongs_to_user = function(user){
    return this.user_id == user;
  }
  this.belongs_to_current_user = function(){
    return this.belongs_to_user(Session.current_session.user_id);
  }

  this.set_color = function(){
    var color = '0x';
    if(this.selected)
      color += "FFFF00";
    else if(!this.belongs_to_current_user()){
      if(this.docked_at)
        color += "99FFFF";
      else
        color += "CC0000";
    }else
      color += "00CC00";

    this.mesh_material =
      UIResources().cached("ship_"+color +"_material",
        function(i) {
          return new THREE.MeshBasicMaterial({color: parseInt(color), overdraw : true});
        });
    if(this.mesh) this.mesh.material = this.mesh_material;
  }
  this.set_color();

  // instantiate mesh to draw ship on canvas
  // see comments related to / around create_mesh and geometry in Asteroid above
  var create_mesh = function(geometry){
    ship.mesh =
      UIResources().cached("ship_" + ship.id + "_mesh",
                           function(i) {
                             var mesh = new THREE.Mesh(geometry, ship.mesh_material);
                             mesh.position.x = ship.location.x;
                             mesh.position.y = ship.location.y;
                             mesh.position.z = ship.location.z;
                             mesh.rotation.x = mesh.rotation.y = mesh.rotation.z = 0;
                             mesh.scale.x = mesh.scale.y = mesh.scale.z = 10;

                             // set orientation
                             mesh.rotation.x = ship.location.orientation_x;
                             mesh.rotation.y = ship.location.orientation_y;
                             mesh.rotation.z = ship.location.orientation_z;

                             return mesh;
                           });

    if(ship.hp > 0) ship.components.push(ship.mesh);

    // reload entity if already in scene
    if(ship.current_scene) ship.current_scene.reload(ship);
  }

  var mesh_geometry =
    UIResources().cached('ship_mesh_geometry',
                         function(i) {
                           var path = UIResources().images_path + '/meshes/brigantine.js';
                           UIResources().load_geometry(path, function(geometry){
                             UIResources().set('ship_mesh_geometry', geometry)
                             create_mesh(geometry);
                           })
                           return null;
                         });

  if(mesh_geometry != null) create_mesh(mesh_geometry);

  // instantiate sphere to draw around ship on canvas
  var sphere_material =
    UIResources().cached('ship_container_material',
      function(i) {
        return new THREE.MeshBasicMaterial( { opacity: 0.0, transparent: true } );
      });

  var sphere_geometry =
    UIResources().cached('ship_container_geometry',
      function(i) {
        var shipradius = 25, shipsegments = 32, shiprings = 32;
        return new THREE.SphereGeometry(shipradius, shipsegments, shiprings);
      });

  this.sphere =
    UIResources().cached("ship_" + this.id + "_container",
                         function(i) {
                           var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
                           sphere.position.x = ship.location.x;
                           sphere.position.y = ship.location.y;
                           sphere.position.z = ship.location.z;
                           sphere.scale.x = sphere.scale.y = sphere.scale.z = 5;
                           return sphere;
                         });

  this.clickable_obj = this.sphere;
  this.components.push(this.sphere);

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
                           var av = ship.mining ?
                                    ship.mining.location : {x:0, y:0, z:0};
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
  this.details = ['Ship: ' + this.id + '<br/>',
                  '@ ' + this.location.to_s() + '<br/>'];
  if(this.belongs_to_user(Session.current_session.user_id)){
    this.details.push("<span id='cmd_move_select' class='commands'>move</span>");
    this.details.push("<span id='cmd_attack_select' class='commands'>attack</span>");
    this.details.push("<span id='cmd_dock_select' class='commands'>dock</span>");
    this.details.push("<span id='cmd_undock' class='commands'>undock</span>");
    this.details.push("<span id='cmd_transfer' class='commands'>transfer</span>");
    this.details.push("<span id='cmd_mine_select' class='commands'>mine</span>");
  }

  // text to render in popup on selection command click
  this.selection =
    { 'cmd_move_select' :
        ['Move Ship',
         function(){
          // coordinate specification
          return this.id + "<br/>" +
                 "X: <input id='dest_x' type='text' value='"+roundTo(this.location.x,2)+"'/><br/>" +
                 "Y: <input id='dest_y' type='text' value='"+roundTo(this.location.y,2)+"'/><br/>" +
                 "Z: <input id='dest_z' type='text' value='"+roundTo(this.location.z,2)+"'/><br/>" +
                 "<input type='button' value='move' id='cmd_move' />"
         }] ,

      'cmd_attack_select' :
        ['Launch Attack',
         function(){
          // load attack target selection from ships in the vicinity
          var entities = Entities().select(function(e) {
            return e.json_class == 'Manufactured::Ship'            &&
                   e.user_id    != Session.current_session.user_id &&
                   e.location.is_within(ship.attack_distance, ship.location);
          });

          var text = "Select " + this.id + " target<br/>";
          for(var e in entities){
            var entity = entities[e];
            text += '<span id="cmd_attack_'+entity.id+'" class="cmd_attack">' + entity.id + '</span>';
          }
          return text;
        }],

      'cmd_dock_select' :
        ['Dock Ship',
         function(){
          // load dock target selection from stations in the vicinity
          var entities = Entities().select(function(e) {
            return e.json_class == 'Manufactured::Station' &&
                   e.location.is_within(100, ship.location);
          });

          var text = 'Dock ' + this.id + ' at<br/>';
          for(var e in entities){
            var entity = entities[e];
            text += '<span id="cmd_dock_' + entity.id + '" class="cmd_dock">' + entity.id + '</span>';
          }
          return text;
        }],

      'cmd_mine_select' :
        ['Start Mining',
         function(){
          // load mining target selection from resource sources in the vicinity
          var entities = Entities().select(function(e) {
            return e.json_class == 'Cosmos::Asteroid' &&
                   e.location.is_within(100, ship.location);
          });

          var text = "Select resource to mine with "+ this.id +" <br/>";
          for(var e in entities){
            var entity = entities[e];

            // refresh lastest asteroid resources
            // XXX rlly don't like using the node here, but simplest / least hacky solution
            Entities().node().web_request('cosmos::get_resource_sources', e.name,
              function(res){
                if(!res.error){
                  for(var r in res.result){
                    var res    = res.result[r];
                    var resid  = res.entity.name + '_' + res.resource.id
                    var restxt = res.resource.type + ": " + res.resource.name + " (" + res.quantity + ")";
                    text += '<span id="cmd_mine_' + rsid + '" class="cmd_mine">'+
                             restxt + '</span>';
                  }
                }
            });
          }
          return text;
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
    // wire up selection command page elements,
    $('#cmd_move_select',
      '#cmd_attack_select',
      '#cmd_dock_select',
      '#cmd_mine_select').
        live('click', function(e){
          // just raise the corresponding event w/ content to display,
          // up to another component to take this and render it
          var cmd     = e.target.id;
          var cmds    = the.selection[cmd];
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
      var eid = e.target.id.substr(11, -1);
      var entity = Entities().get(eid);
      Commands.launch_attack(ship, entity,
                             function(res){
                               ship.raise_event('cmd_attack', ship, entity);
                             });
    })

    $('.cmd_dock').live('click', function(e){
      var eid = e.target.id.substr(9, -1);
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
      Commands.transfer_resources(ship, ship.docked_at,
                                  function(res){
                                    ship.raise_event('cmd_transfer', ship);
                                  });
    })

    $('.cmd_mine').live('click', function(e){
      var rsid = e.target.id.substr(8, -1);
      Commands.start_mining(selected, rsid,
                            function(res){
                              ship.raise_event('cmd_mine', ship, rsid);
                            });
    })

    // change color
    this.selected = true;
    this.set_color();

    // reload ship in scene
    scene.reload_entity(this);
  }

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    $('#cmd_move_select',
      '#cmd_attack_select',
      '#cmd_dock_select',
      '#cmd_mine_select',
      '#cmd_move', '.cmd_attack',
      '#cmd_dock', '#cmd_undock',
      '#cmd_transfer', '#cmd_mine').die();
    this.selected = false;
    this.set_color();
    scene.reload_entity(this);
  }

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }
}

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

  // store stations in the registry
  Entities().set(this.id, this);

  this.location = new Location(this.location);

  this.belongs_to_user = function(user){
    return this.user_id == user;
  }
  this.belongs_to_current_user = function(){
    return this.belongs_to_user(Session.current_session.user_id);
  }

  this.set_color = function(){
    var color = '0x';
    if(this.selected)
      color += "FFFF00";
    else if(!this.belongs_to_current_user())
      color += "CC0011";
    else
      color += "0000CC";

    this.mesh_material =
      UIResources().cached("station_"+color +"_material",
        function(i) {
          return new THREE.MeshBasicMaterial({color: parseInt(color), overdraw : true});
        });
    if(this.mesh) this.mesh.material = this.mesh_material;
  }
  this.set_color();

  // instantiate mesh to draw station on canvas
  // see comments related to / around create_mesh and geometry in Asteroid above
  var create_mesh = function(geometry){
    station.mesh =
      UIResources().cached("station_" + station.id + "_mesh",
                           function(i) {
                             var mesh = new THREE.Mesh(geometry, station.mesh_material);
                             mesh.position.x = station.location.x;
                             mesh.position.y = station.location.y;
                             mesh.position.z = station.location.z;
                             mesh.rotation.x = mesh.rotation.y = mesh.rotation.z = 0;
                             mesh.scale.x = mesh.scale.y = mesh.scale.z = 5;
                             return mesh;
                           });

    station.clickable_obj = station.mesh;
    station.components.push(station.mesh);

    // reload station if already in scene
    if(station.current_scene) station.current_scene.reload(station);
  }

  var mesh_geometry =
    UIResources().cached('station_mesh_geometry',
                         function(i) {
                           var path = UIResources().images_path + '/meshes/research.js';
                           UIResources().load_geometry(path, function(geometry){
                             UIResources().set('station_mesh_geometry', geometry)
                             create_mesh(geometry);
                           })
                           return null;
                         });

  if(mesh_geometry != null) create_mesh(mesh_geometry);

  // some text to render in details box on click
  this.details = ['Station: ' + this.id + '<br/>',
                  '@ ' + this.location.to_s() + '<br/>'];
  if(this.belongs_to_user(Session.current_session.user_id))
    this.details.push("<span id='cmd_construct' class='commands'>construct</span>");

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = function(scene){
    $('#cmd_construct').live('click', function(e){
      Commands.construct_entity(station,
                                function(res){
                                  station.raise_event('cmd_construct',
                                                      res.result[0],
                                                      res.result[1]);
                                });
    });

    this.selected = true;
    this.set_color();
    scene.reload_entity(this);
  }

  /* unselected in scene callback
   */
  this.unselected_in = function(scene){
    $('#cmd_construct').die();

    this.selected = false;
    this.set_color();
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

  // store missions in the registry
  Entities().set(this.id, this);

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
    return this.assigned_to_user(Session.current_session.user_id);
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

  this.json_class = 'Stats::StatResul'
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
