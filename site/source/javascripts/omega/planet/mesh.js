/* Omega Planet Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetMesh = function(config, color, event_cb){
  if(config && event_cb && (typeof(color) != "undefined"))
    this.tmesh = this.init_gfx(config, color, event_cb);
  if(this.tmesh) this.tmesh.omega_obj = this;

  this.spin_angle = 0;
};

Omega.PlanetMesh.prototype = {
  clone : function(){
    var pmesh   = new Omega.PlanetMesh();
    if(this.tmesh) pmesh.tmesh = this.tmesh.clone();
    if(pmesh.tmesh) pmesh.tmesh.omega_obj = pmesh;
    return pmesh;
  },

  init_gfx : function(config, color, event_cb){
    var radius   = 75,
        segments = 32,
        rings    = 32;
    var geo = new THREE.SphereGeometry(radius, segments, rings);
    var mat = Omega.PlanetMaterial.load(config, color, event_cb);
    return new THREE.Mesh(geo, mat);
  },

  _spin_axis : function(){
    if(this.__spin_axis) return this.__spin_axis;

    /// XXX intentionally swapping axis y/z here,
    /// We should generate a unique orientation orthogonal to
    /// orbital axis (or at a slight angle off that) on planet creation
    var loc  = this.omega_entity.location;
    var axis = new THREE.Vector3(loc.orientation_x,
                                 loc.orientation_z,
                                 loc.orientation_y).normalize()
    this.__spin_axis = axis;
    return axis;
  },

  /// TODO optimize
  update : function(){
    if(!this.tmesh) return;
    var entity = this.omega_entity;
    var loc    = entity.location;

    this.tmesh.position.set(loc.x, loc.y, loc.z);
                            
    var rot = new THREE.Matrix4();
    var axis = this._spin_axis();
    rot.makeRotationAxis(axis, this.spin_angle);
    this.tmesh.rotation.setFromRotationMatrix(rot);
  },

  spin : function(angle){
    this.spin_angle += angle;
    if(this.spin_angle > 2*Math.PI) this.spin_angle = 0;
  }
};

Omega.PlanetMaterial = {
  load : function(config, color, event_cb){
    var texture =
      config.resources['planet' + color].material;

    var path =
      config.url_prefix + config.images_path + texture;

    var sphere_texture =
      THREE.ImageUtils.loadTexture(path, {}, event_cb);

    return new THREE.MeshLambertMaterial({map: sphere_texture});
  }
};
