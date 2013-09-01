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
