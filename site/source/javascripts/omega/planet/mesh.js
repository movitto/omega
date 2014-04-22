/* Omega Planet Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetMesh = function(args){
  if(!args) args = {};
  var config   = args['config'];
  var type     = args['type'];
  var event_cb = args['event_cb'];
  var tmesh    = args['tmesh'];

  if(config && typeof(type) !== "undefined")
    this.tmesh = this.init_gfx(config, type, event_cb);
  else if(tmesh)
    this.tmesh = tmesh;

  if(this.tmesh)
    this.tmesh.omega_obj = this;

  this.spin_angle = 0;
};

Omega.PlanetMesh.prototype = {
  props : {
    radius : 75, segments : 32, rings : 32
  },

  valid : function(){
    return this.tmesh != null;
  },

  clone : function(){
    return new Omega.PlanetMesh({tmesh : this.tmesh.clone()});
  },

  _geometry : function(){
    return new THREE.SphereGeometry(this.props.radius,
                                    this.props.segments,
                                    this.props.rings);
  },

  _material : function(config, type, event_cb){
    return Omega.PlanetMaterial.load(config, type, event_cb);
  },

  init_gfx : function(config, type, event_cb){
    return new THREE.Mesh(this._geometry(),
                          this._material(config, type, event_cb));
  },

  _spin_axis : function(){
    if(this.__spin_axis) return this.__spin_axis;

    /// XXX intentionally swapping axis y/z here,
    /// We should generate a unique orientation orthogonal to
    /// orbital axis (or at a slight angle off that) on planet creation
    var loc  = this.omega_entity.scene_location();
    var axis = new THREE.Vector3(loc.orientation_x,
                                 loc.orientation_z,
                                 loc.orientation_y).normalize()
    this.__spin_axis = axis;
    return axis;
  },

  update : function(){
    if(!this.tmesh) return; /// TODO remove conditional
    var entity = this.omega_entity;
    var loc    = entity.scene_location();

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
  load : function(config, type, event_cb){
    var texture =
      config.resources['planet' + type].material;

    var path =
      config.url_prefix + config.images_path + texture;

    var sphere_texture =
      THREE.ImageUtils.loadTexture(path, {}, event_cb);

    return new THREE.MeshLambertMaterial({map: sphere_texture});
  }
};
