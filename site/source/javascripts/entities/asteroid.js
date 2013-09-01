/* Omega Javascript Asteroid
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

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
