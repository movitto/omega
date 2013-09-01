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

