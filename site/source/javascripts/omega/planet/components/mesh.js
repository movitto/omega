/* Omega Planet Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetMesh = function(args){
  if(!args) args = {};
  var tmesh    = args['tmesh'];
  var type     = args['type'];
  var event_cb = args['event_cb'];

  if(tmesh) this.tmesh = tmesh;
  else      this.tmesh = this._mesh(type, event_cb);

  if(this.tmesh) this.tmesh.omega_obj = this;

  this.spin_angle = 0;
};

Omega.PlanetMesh.prototype = {
  props : {
    radius   : 5000,
    segments : 32,
    rings    : 32
  },

  clone : function(){
    return new Omega.PlanetMesh({tmesh : this.tmesh.clone()});
  },

  _geometry : function(){
    return new THREE.SphereGeometry(this.props.radius,
                                    this.props.segments,
                                    this.props.rings);
  },

  _material : function(type, event_cb){
    return Omega.PlanetMaterial.load(type, event_cb);
  },

  _mesh : function(type, event_cb){
    return new THREE.Mesh(this._geometry(),
                          this._material(type, event_cb));
  },

  spin : function(){
    this.tmesh.rotateY(this.spin_angle);
  },

  set_spin : function(angle){
    this.spin_angle = angle;
  }
};

Omega.PlanetMaterial = {
  load : function(type, event_cb){
    var texture = Omega.Config.resources['planet' + type].material;
    var path = Omega.Config.url_prefix + Omega.Config.images_path + texture;
    var sphere_texture = THREE.ImageUtils.loadTexture(path, {}, event_cb);
    sphere_texture.omega_id = 'planet.' + type + '.material';
    return new THREE.MeshLambertMaterial({map: sphere_texture});
  }
};
