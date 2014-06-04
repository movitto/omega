/* Omega Galaxy Center
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.GalaxyCenter = function(args){
  if(!args) args = {};
  config   = args['config'];
  event_cb = args['event_cb'];

  this.init_gfx(config, event_cb);
};

Omega.GalaxyCenter.prototype = {
  _material : function(){
    return new THREE.MeshBasicMaterial({color : 0x000000 });
  },

  _geometry : function(){
    var radius = 750, segments = 32, rings = 32;
    return new THREE.SphereGeometry(radius, segments, rings);
  },

  init_gfx : function(){
    this.mesh = new THREE.Mesh(this._geometry(), this._material());
    this.mesh.omega_obj = this;
  },

  components : function(){
    return [this.mesh];
  }
};
