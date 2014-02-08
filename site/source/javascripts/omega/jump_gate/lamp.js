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
  init_lamp : function(){
    var gfx_props = Omega.JumpGateGfx.gfx_props;
    return new Omega.UI.CanvasLamp({
      size          : 10, color : 0xff0000,
      base_position : [gfx_props.lamp_x,
                       gfx_props.lamp_y,
                       gfx_props.lamp_z]});
  },

  clone : function(){
    /// XXX generates a new lamp, should just clone
    return new Omega.JumpGateLamp();
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;

    this.olamp.set_position(loc.x, loc.y, loc.z);
    Omega.temp_translate(this.olamp.component, loc, function(tlamp){
      Omega.rotate_position(tlamp, loc.rotation_matrix());
    });
  },

  run_effects : function(){
    this.olamp.run_effects();
  }
};
