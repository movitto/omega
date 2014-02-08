/* Omega Ship Mining Vector Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipMiningVector = function(vector){
  this.vector = this.init_gfx();
};

Omega.ShipMiningVector.prototype = {
  clone : function(){
    var mvector = new Omega.ShipMiningVector();
    mvector.vector = this.vector.clone();
    return mvector;
  },

  init_gfx : function(){
    var mining_material = new THREE.LineBasicMaterial({color: 0x0000FF});
    var mining_geo      = new THREE.Geometry();
    mining_geo.vertices.push(new THREE.Vector3(0,0,0));
    mining_geo.vertices.push(new THREE.Vector3(0,0,0));
    return new THREE.Line(mining_geo, mining_material);
  },

  update : function(){
    var loc = this.omega_entity.location;
    this.vector.position.set(loc.x, loc.y, loc.z);
  },

  set_target : function(target_entity){
    var entity = this.omega_entity;
    var loc    = entity.location;

    /// should be signed to preserve direction
    var dx = target_entity.location.x - loc.x;
    var dy = target_entity.location.y - loc.y;
    var dz = target_entity.location.z - loc.z;

    // update mining vector vertices
    this.vector.geometry.vertices[0].set(0,0,0);
    this.vector.geometry.vertices[1].set(dx,dy,dz);
  }
};
