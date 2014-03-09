/* Omega Station Lamps Gfx
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

Omega.StationLamps = function(args){
  if(!args) args = {};
  var config = args['config'];
  var type   = args['type'];

  if(config && type)
    this.olamps = this.init_lamps(config, type);
  else
    this.olamps = [];
}

Omega.StationLamps.prototype = {
  init_lamps : function(config, type){
    var lamps  = config.resources.stations[type].lamps;
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
    for(var l = 0; l < this.olamps.length; l++)
      this.olamps[l].init_gfx();
  },

  clone : function(){
    var slamps = new Omega.StationLamps();
    for(var l = 0; l < this.olamps.length; l++){
      var lamp = this.olamps[l].clone();
      slamps.olamps.push(lamp);
    }
    return slamps;
  },

  update : function(){
    var entity = this.omega_entity;
    var loc    = entity.location;

    for(var l = 0; l < this.olamps.length; l++){
      var lamp = this.olamps[l];
      lamp.set_position(loc.x, loc.y, loc.z);
      Omega.temp_translate(lamp.component, loc, function(tlamp){
        Omega.rotate_position(tlamp, loc.rotation_matrix());
      });
    }
  },

  run_effects : function(){
    for(var l = 0; l < this.olamps.length; l++)
      this.olamps[l].run_effects();
  }
};
