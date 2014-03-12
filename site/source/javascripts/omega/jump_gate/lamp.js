/* Omega Jump Gate Lamp Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.JumpGateLamp = function(){
  /// omega lamps
  this.olamp = this.init_lamp();
};

Omega.JumpGateLamp.prototype = {
  offset : [0, -2, 220],

  init_lamp : function(){
    var olamp = new Omega.UI.CanvasLamp({
      size          : 20, color : 0xff0000,
      base_position : this.offset
    });
    olamp.set_position(0, 0, 0);
    return olamp;
  },

  clone : function(){
    /// XXX generates a new lamp, should just clone
    return new Omega.JumpGateLamp();
  },

  run_effects : function(){
    this.olamp.run_effects();
  }
};
