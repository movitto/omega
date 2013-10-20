/* Omega Javascript SolarSystem
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

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

  // override update
  this.old_update = this.update;
  this.update = _solar_system_update;

  // initialize missing children
  if(!this.stars)      this.stars      = [];
  if(!this.planets)    this.planets    = [];
  if(!this.asteroids)  this.asteroids  = [];
  if(!this.jump_gates) this.jump_gates = [];

  // convert children
  this.location = new Location(this.location);
  if(this.children){
    for(var c = 0; c < this.children.length; c++){
      if(this.children[c].json_class == 'Cosmos::Entities::Star')
        this.stars.push(new Star(this.children[c]))
      else if(this.children[c].json_class == 'Cosmos::Entities::Planet')
        this.planets.push(new Planet(this.children[c]))
      else if(this.children[c].json_class == 'Cosmos::Entities::Asteroid')
        this.asteroids.push(new Asteroid(this.children[c]))
      else if(this.children[c].json_class == 'Cosmos::Entities::JumpGate')
        this.jump_gates.push(new JumpGate(this.children[c]))
    }
  }

  // adding jump gates lines is defered to later when we
  // can remotely retrieve endpoint systems
  this.add_jump_gate = _solar_system_add_jump_gate;

  // load solar system graphical resources
  _solar_system_load_mesh(this);
  _solar_system_load_plane(this);
  _solar_system_load_text(this);

  // return children
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
      for(var e = 0; e < res.result.length; e++){
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

/* SolarSystem::update method
 */
function _solar_system_update(oargs){
  var args = $.extend({}, oargs); // copy args

  if(args.location && this.location){
    this.location.update(args.location);
    delete args.location;
  }
  if(args.stars && this.stars){
    for(var s = 0; s < args.stars.length; s++)
      this.stars[s].update(args.stars[s]);
    delete args.stars;
  }
  // assuming that planets/asteroids/jump gates lists are not variable
  // (though individual properties such as location may be)
  if(args.planets && this.planets){
    for(var p = 0; p < args.planets.length; p++)
      this.planets[p].update(args.planets[p]);
    delete args.planets
  }
  if(args.asteroids && this.asteroids){
    for(var a = 0; a < args.asteroids.length; a++)
      this.asteroids[a].update(args.asteroids[a]);
    delete args.asteroids
  }
  if(args.jump_gates && this.jump_gates){
    for(var j = 0; j < args.jump_gates.length; j++)
      this.jump_gates[j].update(args.jump_gates[j]);
    delete args.jump_gates
  }

  // do not update components
  if(args.components) delete args.components;

  this.old_update(args);
}

/* SolarSystem::add_jump_gate method
 */
function _solar_system_add_jump_gate(jg, endpoint){
  var system = this;

  ////////////////////////// add line between systems
  var line_geometry =
    UIResources().cached("jump_gate_" + this.name + "-" + endpoint.name + "_line_geometry",
      function(i) {
        var geometry = new THREE.Geometry();
        geometry.vertices.push(new THREE.Vector3(system.location.x,
                                                 system.location.y - 50,
                                                 system.location.z));

        geometry.vertices.push(new THREE.Vector3(endpoint.location.x,
                                                 endpoint.location.y + 50,
                                                 endpoint.location.z));
        return geometry;
    });

  var line_material =
    UIResources().cached("jump_gate_line_material",
      function(i) {
        return new THREE.LineBasicMaterial({color: 0xF80000});
    });

  var line =
    UIResources().cached("jump_gate_" + this.name + "-" + endpoint.name + "_line",
      function(i) {
        return new THREE.Line(line_geometry, line_material);
    });

  _sys_adj_orientation(line.geometry.vertices[0]);
  _sys_adj_orientation(line.geometry.vertices[1]);
  this.components.push(line);

  ////////////////////////// add particle effect to line

  var particle_material =
    UIResources().cached("jump_gate_particle_material",
      function(i) {
        return new THREE.ParticleBasicMaterial({
                     color: 0xFF0000, size: 75,
                     map: UIResources().load_texture(UIResources().images_path + "/particle.png"),
                     blending: THREE.AdditiveBlending, transparent: true });
    });

  var particle_geo =
    UIResources().cached('jump_gate_'+jg.id+'particle_geo',
      function(i) {
        var geo = new THREE.Geometry();
        geo.vertices.push(new THREE.Vector3(0,0,0));
        return geo;
      });

  var particles =
    UIResources().cached('jump_gate_'+jg.id+'particle_system',
      function(i) {
        var particleSystem =
          new THREE.ParticleSystem(particle_geo,
                                   particle_material);
        particleSystem.position.x = system.location.x;
        particleSystem.position.y = system.location.y;
        particleSystem.position.z = system.location.z;
        particleSystem.sortParticles = true;

        particleSystem.ticker = 0;
        particleSystem.update_particles = function(){
          var v = this.geometry.vertices[0];
          var d = system.location.distance_from(endpoint.location.x,
                                                endpoint.location.y,
                                                endpoint.location.z);
          var dx = (endpoint.location.x - system.location.x) / d
          var dy = (endpoint.location.y - system.location.y) / d
          var dz = (endpoint.location.z - system.location.z) / d

          v.set(this.ticker * dx * 50,
                this.ticker * dy * 50,
                this.ticker * dz * 50)

          _sys_adj_orientation(v);
          this.ticker += 1;
          if(this.ticker == 20) this.ticker = 0;

          this.geometry.__dirtyVertices = true;
        };

        return particleSystem;
      });

  _sys_adj_orientation(particles.position);
  this.components.push(particles);

  // if current scene is set, reload
  if(this.current_scene) this.current_scene.reload_entity(this);
}

/* Helper method to load solar system mesh resources
 */
function _solar_system_load_mesh(system){
  // instantiate sphere to represent system on canvas
  var sphere_geometry =
    UIResources().cached('solar_system_sphere_geometry',
      function(i) {
        var radius   = 50, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_material =
    UIResources().cached("solar_system_sphere_material",
      function(i) {
        return new THREE.MeshBasicMaterial({opacity: 0, transparent: true});
      });

  system.sphere =
    UIResources().cached("solar_system_" + system.id + "_sphere",
      function(i) {
        var sphere   = new THREE.Mesh(sphere_geometry, sphere_material);
        sphere.position.x = system.location.x;
        sphere.position.y = system.location.y;
        sphere.position.z = system.location.z ;
        _sys_adj_orientation(sphere.position);
        return sphere;
      });

  system.clickable_obj = system.sphere;
  system.components.push(system.sphere);
}

function _solar_system_load_plane(system){
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

  system.plane =
    UIResources().cached("solar_system_" + system.id + "_plane_mesh",
      function(i) {
        var plane = new THREE.Mesh(plane_geometry, plane_material);
        plane.position.x = system.location.x;
        plane.position.y = system.location.y;
        plane.position.z = system.location.z;
        _sys_adj_orientation(plane.position);

        plane.rotation.x = -1.57;
        return plane;
      });

  system.components.push(system.plane);
}

function _solar_system_load_text(system){
  // instantiate text to draw system name to canvas
  var text3d =
    UIResources().cached("solar_system_" + system.id + "label_geometry",
      function(i) {
        var geo = new THREE.TextGeometry( system.name, {height: 12, width: 5, curveSegments: 2, font: 'helvetiker', size: 48});
        THREE.GeometryUtils.center(geo);
        return geo;
      });

  var text_material =
    UIResources().cached("solar_system_text_material",
      function(i) {
        return new THREE.MeshBasicMaterial( { color: 0x3366FF, overdraw: true } );
      });

  system.text =
    UIResources().cached("solar_system_" + system.id + "label",
      function(i) {
        var text = new THREE.Mesh( text3d, text_material );
        text.position.x = system.location.x;
        text.position.y = system.location.y;
        text.position.z = system.location.z - 50;
        _sys_adj_orientation(text.position);
        return text;
      });

  system.components.push(system.text);
}

// XXX hack to adjust various system components to accomodate for galaxy mesh adjustments
function _sys_adj_orientation(pos){
  var np = rot(pos.x,pos.y,pos.z,1.57,1,0,0)
  pos.set(np[0],np[1],np[2])
}
