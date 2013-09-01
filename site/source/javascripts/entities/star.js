/* Omega Javascript Star
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

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
