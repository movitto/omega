/* Omega JS Canvas Lamp Scene Component
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// Make sure to specify
///   - id
///   - size
///   - color
///   - base_position
Omega.UI.CanvasLamp = function(parameters){
  this.base_position = [0,0,0];

  this.components = [];
  $.extend(this, parameters);

  /// reduce color components seperately
  this.diff  = ((this.color & 0xff0000) != 0) ? 0x050000 : 0;
  this.diff += ((this.color & 0x00ff00) != 0) ? 0x000500 : 0;
  this.diff += ((this.color & 0x0000ff) != 0) ? 0x000005 : 0;
};

Omega.UI.CanvasLamp.prototype = {
  set_position : function(x,y,z){
    this.position = [x,y,z];
    if(this.lamp)
      this.lamp.position.set(x + this.base_position[0],
                             y + this.base_position[1],
                             z + this.base_position[2]);
  },

  init_gfx : function(){
    if(this.components.length > 0) return;

    var geometry = new THREE.SphereGeometry(this.size, 32, 32);
    var material = new THREE.MeshBasicMaterial({color: this.color});
    this.lamp    = new THREE.Mesh(geometry, material);
    if(this.position) this.set_position(this.position[0],
                                        this.position[1],
                                        this.position[2]);
    this.component  =  this.lamp;
    this.components = [this.lamp];
  },

  run_effects : function(loc, percentage){
    var ccolor = this.lamp.material.color.getHex();
    var ncolor = ccolor - this.diff;
    this.lamp.material.color.setHex(ncolor < 0x000050 ? this.color : ncolor);
  },

  clone : function(){
    return new Omega.UI.CanvasLamp({id    : this.id,
                                    size  : this.size,
                                    color : this.color,
                                    base_position : this.base_position});
  }
};

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasLamp.prototype );
