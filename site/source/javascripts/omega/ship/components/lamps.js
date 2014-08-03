/* Omega Ship Lamps Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

Omega.ShipLamps = function(args){
  if(!args) args = {};
  var type   = args['type'];

  if(type) this.olamps = this._lamps(type);
  else     this.olamps = [];
}

Omega.ShipLamps.prototype = {
  _lamps : function(type){
    var lamps  = Omega.Config.resources.ships[type].lamps;
    var olamps = [];
    if(lamps){
      for(var l = 0; l < lamps.length; l++){
        var lamp  = lamps[l];
        var olamp = new Omega.UI.CanvasLamp({size : lamp[0],
                                             color: lamp[1],
                                     base_position: lamp[2]});
        olamps.push(olamp);
      }
    }

    return olamps;
  },

  init_gfx : function(){
    for(var l = 0; l < this.olamps.length; l++){
      this.olamps[l].init_gfx();
      this.olamps[l].set_position(0,0,0);
    }
  },

  clone : function(){
    var slamps = new Omega.ShipLamps();
    for(var l = 0; l < this.olamps.length; l++){
      var lamp = this.olamps[l].clone();
      slamps.olamps.push(lamp);
    }
    return slamps;
  },

  run_effects : function(){
    for(var l = 0; l < this.olamps.length; l++)
      this.olamps[l].run_effects();
  }
};
