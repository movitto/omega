/* Omega Javascript JumpGate
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

/* Omega Jump Gate
 */
function JumpGate(args){
  $.extend(this, new Entity(args));
  $.extend(this, new CanvasComponent(args));

  //this.id = this.solar_system + '-' + this.endpoint;

  var jg = this;
  this.json_class = 'Cosmos::Entities::JumpGate';

  // convert location
  this.location = new Location(this.location);

  // instantiate mesh to draw gate on canvas
  _jump_gate_load_mesh(this);
  this.create_mesh = _jump_gate_create_mesh;
  this.create_mesh();

  // instantiate lamps to draw on gate
  _jump_gate_create_lamp(this);

  // instantiate particle effects to draw on gate
  _jump_gate_load_effects(this);

  // instantiate sphere to draw around jump_gate on canvas
  _jump_gate_load_selection_sphere(this);

  // some text to render in details box on click
  this.details = _jump_gate_render_details;

  /* added_to scene callback
   */
  this.added_to = function(scene){
    this.current_scene = scene;
  }

  /* clicked_in scene callback
   */
  this.clicked_in = _jump_gate_clicked_in;

  /* unselected in scene callback
   */
  this.unselected_in = _jump_gate_unselected_in;

  /* removed_from scene callback
   */
  this.removed_from = function(scene){
    this.current_scene = null;
  }
}

///////////////////////// private helper / utility methods

/* JumpGate::create_mesh method
 */
function _jump_gate_create_mesh(){
  var jg = this;
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
          mesh.matrix.makeRotationFromEuler(mesh.rotation);
        }
 
        return mesh;
      });

  this.shader_mesh =
    UIResources().cached("jump_gate" + this.id + "_shader_mesh",
      function(i) {
        var mesh = new THREE.Mesh(jg.mesh_geometry.clone(),
                                  new THREE.MeshBasicMaterial({color: 0x000000}));
        mesh.position = jg.mesh.position;
        mesh.rotation = jg.mesh.rotation;
        mesh.scale    = jg.mesh.scale;
        return mesh;
      });

  this.clickable_obj = this.mesh;
  this.components.push(this.mesh);
  this.shader_components.push(this.shader_mesh);

  // reload entity if already in scene
  if(this.current_scene) this.current_scene.reload_entity(this);
}

/* Helper to load jump gate mesh resources
 */
function _jump_gate_load_mesh(jg){
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

  jg.mesh_material =
    UIResources().cached("jump_gate_mesh_material",
      function(i) {
        return new THREE.MeshLambertMaterial( { map: mesh_texture } );
      });

  jg.mesh_geometry =
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
}

/* Helper to create jump gate lamp
 */
function _jump_gate_create_lamp(jg){
  jg.lamp = create_lamp(10, 0xff0000);
  jg.lamp.position.set(jg.location.x -  22,
                        jg.location.y -  17,
                        jg.location.z + 175)
  jg.components.push(jg.lamp);
}

/* Helper to load jump gate effects
 */
function _jump_gate_load_effects(jg){
  var plane = 20, lifespan = 200;
  var pMaterial =
    UIResources().cached('jump_gate_effect1_mat',
      function(i) {
        return new THREE.ParticleBasicMaterial({
         color: 0x0000FF, size: 20,
         map: UIResources().load_texture(UIResources().images_path + "/particle.png"),
         blending: THREE.AdditiveBlending, transparent: true });
       });

  var particles = 
    UIResources().cached('jump_gate_effect1_geo',
      function(i) {
        var geo = new THREE.Geometry();
        for(var i = 0; i < plane; ++i){
          for(var j = 0; j < plane; ++j){
            var pv = new THREE.Vector3(i, j, 0);
            pv.velocity = Math.random();
            pv.lifespan = lifespan;
            pv.moving = false;
            geo.vertices.push(pv)
          }
        }
        return geo;
      });

  jg.effects1 = new THREE.ParticleSystem(particles, pMaterial);
  jg.effects1.position.set(jg.location.x + -30,
                           jg.location.y + -25,
                           jg.location.z +  75)
  jg.effects1.sortParticles = true;

  jg.effects1.update_particles = function(){
    var p = plane*plane;
    var not_moving = [];
    while(p--){
      var pv = this.geometry.vertices[p]
      if(pv.moving){
        pv.z -= pv.velocity;
        pv.lifespan -= 1;
        if(pv.lifespan < 0){
          pv.z = 0;
          pv.lifespan = 200;
          pv.moving = false;
        }
      }else{
        not_moving.push(pv);
      }
    }
    not_moving[Math.floor(Math.random()*(not_moving.length-1))].moving = true;
    this.geometry.__dirtyVertices = true;
  }

  jg.components.push(jg.effects1);
}

/* Helper to load jump gate selection sphere
 */
function _jump_gate_load_selection_sphere(jg){
  var sphere_geometry =
    UIResources().cached('jump_gate_' + jg.trigger_distance + '_container_geometry',
      function(i) {
        var radius    = jg.trigger_distance, segments = 32, rings = 32;
        return new THREE.SphereGeometry(radius, segments, rings);
      });

  var sphere_material =
    UIResources().cached("jump_gate_container_material",
      function(i) {
        return new THREE.MeshBasicMaterial({color: 0xffffff,
                                            transparent: true,
                                            opacity: 0.1});

      });

  jg.sphere =
    UIResources().cached("jump_gate_" + jg.id + "_container",
                         function(i) {
                           var sphere = new THREE.Mesh(sphere_geometry, sphere_material);
                           sphere.position.x = jg.location.x - 20;
                           sphere.position.y = jg.location.y;
                           sphere.position.z = jg.location.z;
                           sphere.scale.x = sphere.scale.y = sphere.scale.z = 5;
                           return sphere;
                         });
}

/* JumpGate::details method
 */
function _jump_gate_render_details(){
  return ['Jump Gate to ' + this.endpoint_id + '<br/>',
          '@ ' + this.location.to_s() + "<br/><br/>",
          "<span class='commands' id='cmd_trigger_jg'>Trigger</div>"];
}

/* JumpGate::clicked_in method
 */
function _jump_gate_clicked_in(scene){
  var jg = this;
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

/* JumpGate::unselected_in method
 */
function _jump_gate_unselected_in(scene){
  this.selected = false;

  scene.reload_entity(this, function(s,e){
    var si = e.components.indexOf(e.sphere);
    if(si != -1) e.components.splice(si, 1);
    e.clickable_obj = e.mesh;
  });
}
