/* Omega Solar System Mesh
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.SolarSystemMesh = function(mesh){
  this.tmesh = mesh ? mesh : this.init_gfx();
  this.tmesh.omega_obj = this;
};

Omega.SolarSystemMesh.prototype = {
  clone : function(){
    return new Omega.SolarSystemMesh(this.tmesh.clone());
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.tmesh.position.set(loc.x, loc.y, loc.z);
  },

  _material : function(){
    return new THREE.MeshBasicMaterial({opacity: 0.2,
                                        transparent: true});
  },

  _geometry : function(){
    var radius = 50, segments = 32, rings = 32;
    return new THREE.SphereGeometry(radius, segments, rings);
  },

  init_gfx : function(){
    return new THREE.Mesh(this._geometry(), this._material());
  }
};
