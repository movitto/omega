/* Omega Planet Axis Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.PlanetAxis = function(args){
  if(!args) args = {};
  this.init_gfx();
};

Omega.PlanetAxis.prototype = {
  length : 7500,
  color  : 'red',

  clone : function(){
    return new Omega.PlanetAxis();
  },

  init_gfx : function(color){
    var mat = new THREE.LineBasicMaterial({color : this.color});
    var geo = new THREE.Geometry();
    geo.vertices.push(new THREE.Vector3(0, -this.length, 0));
    geo.vertices.push(new THREE.Vector3(0,  this.length, 0));
    this.mesh = new THREE.Line(geo, mat);
  }
};
