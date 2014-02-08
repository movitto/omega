/* Omega Jump Gate Selection Gfx & Helpers
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateSelectionMaterial = function(){
  this.material =
    new THREE.MeshBasicMaterial({color       : 0xffffff,
                                 transparent :     true,
                                 depthWrite  :    false,
                                 opacity     :      0.1});
};

Omega.JumpGateSelection = function(size){
  this.tmesh = this.init_gfx(size);
};

Omega.JumpGateSelection.prototype = {
  init_gfx : function(size){
    var segments = 32, rings = 32,
        material = Omega.JumpGate.gfx.selection_material.material;
    var geometry = new THREE.SphereGeometry(size, segments, rings);
    return new THREE.Mesh(geometry, material);
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;
    this.tmesh.position.set(loc.x - 20, loc.y, loc.z)
  }
};

Omega.JumpGateSelection.for_jg = function(gate){
  return new Omega.JumpGateSelection(gate.trigger_distance/2);
};
