/* Omega Ship HP Bar Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/canvas/components/progress_bar'

Omega.ShipHpBar = function(args){
  if(!args) args = {};
  var event_cb = args['event_cb'];
  this.bar = args['bar'] || this._progress_bar(event_cb);
};

Omega.ShipHpBar.prototype = {
  size : [100, 10],

  clone : function(){
    return new Omega.ShipHpBar({bar : this.bar.clone()});
  },

  _progress_bar : function(event_cb){
    var bar = new Omega.UI.CanvasProgressBar({size     : this.size,
                                              color1   : 0x0000FF,
                                              color2   : 0xFF0000,
                                              event_cb : event_cb});
    for(var c = 0; c < bar.components.length; c++)
      bar.components[c].position.set(-100, 100, 0);
    return bar;
  },

  update : function(){
    var entity = this.omega_entity;
    this.bar.update(entity.hp/entity.max_hp);
  }
};
