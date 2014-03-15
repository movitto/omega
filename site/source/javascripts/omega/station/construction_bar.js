/* Omega Station Construction Bar Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationConstructionBar = function(args){
  if(!args) args = {};
  this.bar = args['bar'] || this.init_gfx();
};

Omega.StationConstructionBar.prototype = {
  clone : function(){
    return new Omega.StationConstructionBar({bar : this.bar.clone()});
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
    var entity = this.omega_entity;

    if(entity.construction_percent > 0){
      this.bar.update(entity.construction_percent);

      if(!entity._has_construction_bar())
        entity._add_construction_bar();

    }else if(entity._has_construction_bar()){
      entity._rm_construction_bar();
    }
  }
};

/// Gets mixed into Omega.StationGfx
Omega.StationConstructionGfxHelpers = {
  _has_construction_bar : function(){
    if(!this.mesh) return false;
    var component   = this.construction_bar.bar.components[0];
    var descendants = this.mesh.tmesh.getDescendants();
    return descendants.indexOf(component) != -1;
  },

  _add_construction_bar : function(){
    if(!this.mesh) return;
    for(var c = 0; c < this.construction_bar.bar.components.length; c++)
      this.mesh.tmesh.add(this.construction_bar.bar.components[c]);
  },

  _rm_construction_bar : function(){
    if(!this.mesh) return;
    for(var c = 0; c < this.construction_bar.bar.components.length; c++)
      this.mesh.tmesh.remove(this.construction_bar.bar.components[c]);
  }
};
