/* Omega Solar System Plane
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemPlane = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];
  var tmesh    = args['tmesh'];

  if(tmesh)
    this.tmesh = tmesh;
  else
    this.tmesh = this._mesh(event_cb);

  if(this.tmesh)
    this.tmesh.omega_obj = this;
};

Omega.SolarSystemPlane.prototype = {
  valid : function(){
    return this.tmesh != null;
  },

  clone : function(){
    return new Omega.SolarSystemPlane({tmesh: this.tmesh.clone()});
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.tmesh.position.set(loc.x, loc.y, loc.z);
  },

  _material : function(event_cb){
    var texture_path = Omega.Config.url_prefix + Omega.Config.images_path +
                       Omega.Config.resources.solar_system.material;

    var texture   = THREE.ImageUtils.loadTexture(texture_path, {}, event_cb);
    var material  = new THREE.MeshBasicMaterial({map: texture, alphaTest: 0.5});
    material.side = THREE.DoubleSide;

    return material;
  },

  _geometry : function(){
    return new THREE.PlaneGeometry(100, 100);
  },

  _mesh : function(event_cb){
    var geo  = this._geometry();
    var mat  = this._material(event_cb);

    var mesh = new THREE.Mesh(geo, mat);
    mesh.rotation.x = 1.57;
    return mesh;
  }
};
