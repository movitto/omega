/* Omega Station Construction Bar Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationConstructionBar = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];
  this.bar = args['bar'] || this._progress_bar(event_cb);
};

Omega.StationConstructionBar.prototype = {
  size : [1000, 100],

  clone : function(){
    return new Omega.StationConstructionBar({bar : this.bar.clone()});
  },

  _progress_bar : function(event_cb){
    var bar = new Omega.UI.CanvasProgressBar({size     : this.size,
                                              color1   : 0x00FF00,
                                              color2   : 0x0000FF,
                                              event_cb : event_cb});
    for(var c = 0; c < bar.components.length; c++)
      bar.components[c].position.set(0, 2000, 0);
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
    var descendants = this.position_tracker().getDescendants();
    return descendants.indexOf(component) != -1;
  },

  _add_construction_bar : function(){
    if(!this.mesh) return;
    for(var c = 0; c < this.construction_bar.bar.components.length; c++)
      this.position_tracker().add(this.construction_bar.bar.components[c]);
  },

  _rm_construction_bar : function(){
    if(!this.mesh) return;
    for(var c = 0; c < this.construction_bar.bar.components.length; c++)
      this.position_tracker().remove(this.construction_bar.bar.components[c]);
  }
};
