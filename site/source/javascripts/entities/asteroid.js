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

  var asteroid = this;
  this.json_class = 'Cosmos::Entities::Asteroid';

  // convert location
  this.location = new Location(this.location);

  // instantiate mesh to draw asteroid on canvas
  this.create_mesh = _asteroid_create_mesh;
  _asteroid_load_mesh_resources(this);
  this.create_mesh();

  // some text to render in details box on click
  this.details = _asteroid_render_details;

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

///////////////////////// private helper / utility methods

/* Asteroid::update method
 */
function _asteroid_update(oargs){
  var args = $.extend({}, oargs); // copy args
}

/* Asteroid::create_mesh method
 */
function _asteroid_create_mesh(){
  var asteroid = this;

  if(this.mesh_geometry == null) return;
  var mesh =
    UIResources().cached("asteroid_" + this.id + "_mesh",
      function(i) {
        var mesh = new THREE.Mesh(asteroid.mesh_geometry, asteroid.mesh_material);
        mesh.position.x = asteroid.location.x;
        mesh.position.y = asteroid.location.y;
        mesh.position.z = asteroid.location.z;

        var scale = $omega_config.resources['asteroid'].scale;
        if(scale)
          mesh.scale.set(scale[0], scale[1], scale[2]);

        var rotation = $omega_config.resources['asteroid'].rotation;
        if(rotation){
          mesh.rotation.set(rotation[0], rotation[1], rotation[2]);
          mesh.rotation.z += Math.random() * 3.14;
        }

        return mesh;
      });

  this.clickable_obj = mesh;
  this.components.push(mesh);

  // reload asteroid if already in scene
  if(this.current_scene) this.current_scene.reload_entity(this);
}

/* Helper to load asteroid mesh resources
 */
function _asteroid_load_mesh_resources(ast){
  ast.mesh_texture =
    UIResources().cached("asteroid_texture",
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['asteroid']['material'];
        return UIResources().load_texture(path);
      });

  ast.mesh_material =
    UIResources().cached("asteroid_material",
      function(i) {
        return new THREE.MeshLambertMaterial({map: ast.mesh_texture});
        //return new THREE.MeshBasicMaterial( { color: 0x666600, wireframe: false });
      });

  ast.mesh_geometry =
    UIResources().cached('asteroid_geometry',
      function(i) {
        var path = UIResources().images_path + $omega_config.resources['asteroid']['geometry'];
        UIResources().load_geometry(path, function(geo){
          ast.mesh_geometry = geo;
          UIResources().set('asteroid_geometry', ast.mesh_geometry);
          ast.create_mesh();
        })
        return null;
      });
}

/* Asteroid::details method
 */
function _asteroid_render_details(){
  return ['Asteroid: ' + this.name + "<br/>",
          '@ ' + this.location.to_s() + '<br/>'];
}
