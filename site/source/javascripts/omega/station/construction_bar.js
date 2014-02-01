/* Omega Station Construction Bar Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationConstructionBar = function(bar){
  this.bar = bar ? bar : this.init_gfx();
};

Omega.StationConstructionBar.prototype = {
  clone : function(){
    return new Omega.StationConstructionBar(this.bar.clone());
  },

  construction_bar_props : {
    length: 200
  },

  init_gfx : function(){
    var len = this.construction_bar_props.length;
    var bar =
      new Omega.UI.CanvasProgressBar({
        width: 3, length: len, axis : 'x',
        color1: 0x00FF00, color2: 0x0000FF,
        vertices: [[[-len/2, 100, 0],
                    [-len/2, 100, 0]],
                   [[-len/2, 100, 0],
                    [ len/2, 100, 0]]]});
    return bar;
  },

  update : function(){
    if(!this.bar) return;
    var entity = this.omega_entity;
    var loc    = entity.location;

    if(entity.construction_percent > 0){
      this.bar.update(loc, entity.construction_percent);

      if(!entity._has_construction_bar())
        entity._add_construction_bar();

    }else if(entity._has_construction_bar()){
      entity._rm_construction_bar();
    }
  }
};
