/* Omega Ship HP Bar Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipHpBar = function(args){
  if(!args) args = {};
  this.bar = args['bar'] || this.load_bar();
};

Omega.ShipHpBar.prototype = {
  clone : function(){
    return new Omega.ShipHpBar({bar : this.bar.clone()});
  },

  health_bar_props : {
    length : 200
  },

  load_bar : function(){
    var len = this.health_bar_props.length;
    var bar =
      new Omega.UI.CanvasProgressBar({
        width : 3, length: len, axis : 'x',
        color1: 0xFF0000, color2: 0x0000FF,
        vertices: [[[-len/2, 100, 0],
                    [-len/2, 100, 0]],
                   [[-len/2, 100, 0],
                    [ len/2, 100, 0]]]});
    return bar;
  },

  init_gfx : function(){
    this.bar.init_gfx();
  },

  update : function(){
    var entity = this.omega_entity;
    this.bar.update(entity.hp/entity.max_hp);
  }
};
