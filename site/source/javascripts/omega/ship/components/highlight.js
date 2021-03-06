/* Omega Ship Highlight Effects Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipHighlightEffects = function(args){
  if(!args) args = {};

  this.mesh = args['mesh'] || this.init_gfx(); 
  this.mesh.omega_obj = this;
};

Omega.ShipHighlightEffects.prototype = {
  clone : function(){
    return new Omega.ShipHighlightEffects({mesh: this.mesh.clone()});
  },

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  init_gfx : function(){
    var highlight_props    = this.highlight_props;
    var highlight_geometry = new THREE.CylinderGeometry( 0, 40, 80, 8, 2 );
    var highlight_material = new THREE.MeshBasicMaterial({ color:0x33ff33,
                                                           shading: THREE.FlatShading } );
    var highlight_mesh     = new THREE.Mesh(highlight_geometry, highlight_material);
    highlight_mesh.position.set(highlight_props.x,
                                highlight_props.y,
                                highlight_props.z);
    highlight_mesh.rotation.set(highlight_props.rot_x,
                                highlight_props.rot_y,
                                highlight_props.rot_z);
    return highlight_mesh;
  }
}
