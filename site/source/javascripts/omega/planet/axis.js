/* Omega Planet Axis Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetAxis = function(args){
  if(!args) args = {};
  this.init_gfx();
};

Omega.PlanetAxis.prototype = {
  length : 250,
  color  : 'red',

  clone : function(){
    return new Omega.PlanetAxis();
  },

  init_gfx : function(color){
    var mat = new THREE.LineBasicMaterial({color : this.color});
    var geo = new THREE.Geometry();
    geo.vertices.push(new THREE.Vector3(0,0,0));
    geo.vertices.push(new THREE.Vector3(0,0,0));
    this.mesh = new THREE.Line(geo, mat);
  },

  set_orientation : function(x,y,z){
    var v0 = this.mesh.geometry.vertices[0];
    var v1 = this.mesh.geometry.vertices[1];

    /// XXX see note in planet/mesh#_spin_axis about
    /// intentionally swapping y & z
    v0.set(-x * this.length, -z * this.length, -y * this.length);
    v1.set( x * this.length,  z * this.length,  y * this.length);

    this.mesh.geometry.verticesNeedUpdate = true;
  }
};
