/* Omega Javascript Planet
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

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
