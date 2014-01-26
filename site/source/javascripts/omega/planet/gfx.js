/* Omega Planet Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

///////////////////////////////////////// high level operations

Omega.load_planet_gfx = function(config, color, event_cb){
  var gfx = {};
  gfx.mesh = new Omega.PlanetMesh(config, color, event_cb);
  Omega.Planet.gfx[color] = gfx;
};

Omega.init_planet_gfx = function(config, planet, event_cb){
  var color = planet.colori();
  planet.mesh = Omega.Planet.gfx[color].mesh.clone();
  planet.mesh.omega_entity = planet;
  planet.mesh.material = new Omega.load_planet_material(config, color, event_cb);
  planet.update_gfx();

  planet._calc_orbit();
  planet.orbit_line = new Omega.PlanetOrbitLine(planet.orbit);

  planet.components = [planet.mesh, planet.orbit_line.line];
};

Omega.update_planet_gfx = function(planet){
  planet._update_mesh();
}

///////////////////////////////////////// initializers

Omega.load_planet_material = function(config, color, event_cb){
  var texture = config.resources['planet' + color].material;
  var path    = config.url_prefix + config.images_path + texture;
  var sphere_texture = THREE.ImageUtils.loadTexture(path, {}, event_cb);
  return new THREE.MeshLambertMaterial({map: sphere_texture});
};

Omega.PlanetMesh = function(config, color, event_cb){
  var radius   = 75,
      segments = 32,
      rings    = 32;
  var geo = new THREE.SphereGeometry(radius, segments, rings);
  var mat = Omega.load_planet_material(config, color, event_cb);
  $.extend(this, new THREE.Mesh(geo, mat));
};

///////////////////////////////////////// update methods

/// This module gets mixed into Planet
Omega.PlanetGfxUpdaters = {
  _update_mesh : function(){
    if(!this.mesh) return;
    this.mesh.position.set(this.location.x,
                           this.location.y,
                           this.location.z);
    if(this.spin_angle){
      var rot = new THREE.Matrix4();

      /// XXX intentionally swapping axis y/z here,
      /// We should generate a unique orientation orthogonal to
      /// orbital axis (or at a slight angle off that) on planet creation
      rot.makeRotationAxis(new THREE.Vector3(this.location.orientation_x,
                                             this.location.orientation_z,
                                             this.location.orientation_y).normalize(),
                           this.spin_angle);
      //this.mesh.matrix.multiply(rot);
      rot.multiply(this.mesh.matrix);
      this.mesh.matrix = rot;
      this.mesh.rotation.setFromRotationMatrix(this.mesh.matrix);
    }
  }
}

///////////////////////////////////////// other

/// Gets mixed into the Planet Module
Omega.PlanetEffectRunner = {
  run_effects : function(){
    var ms   = this.location.movement_strategy;
    var curr = new Date();
    if(!this.last_moved){
      this.last_moved = curr;
      this.spin_angle = 0;
      return;
    }

    var elapsed = curr - this.last_moved;
    var dist = ms.speed * elapsed / 1000;

    var n = Omega.Math.rot(this.location.x-this.cx,
                           this.location.y-this.cy,
                           this.location.z-this.cz,
                             - this.rot_axis.angle,
                             this.rot_axis.axis[0],
                             this.rot_axis.axis[1],
                             this.rot_axis.axis[2])

        n = Omega.Math.rot(n[0], n[1], n[2],
                        -this.rot_plane.angle,
                            this.rot_plane.axis[0],
                            this.rot_plane.axis[1],
                            this.rot_plane.axis[2]);

    var x = n[0] ; var y = n[1]; /// z should == 0

    // calc current angle (x = a*Math.cos(i))
    var angle = Math.acos(x/this.a)
    if(y < 0) angle = 2 * Math.PI - angle;

    // calculate new angle
    var new_angle = dist + angle;

    // calculate new position
    var x = this.a * Math.cos(new_angle);
    var y = this.b * Math.sin(new_angle);
    var n = Omega.Math.rot(x, y, 0,
                  this.rot_plane.angle,
                this.rot_plane.axis[0],
                this.rot_plane.axis[1],
                this.rot_plane.axis[2])


        n = Omega.Math.rot(n[0], n[1], n[2], 
                        this.rot_axis.angle,
                      this.rot_axis.axis[0],
                      this.rot_axis.axis[1],
                      this.rot_axis.axis[2]);

    this.location.x = n[0] + this.cx;
    this.location.y = n[1] + this.cy;
    this.location.z = n[2] + this.cz;

    this.spin_angle += elapsed / 500000;
    if(this.spin_angle > 2*Math.PI) this.spin_angle = 0;

    this.update_gfx();
    this.last_moved = curr;
  }
}
