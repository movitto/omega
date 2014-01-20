/* Omega Station JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/station/commands"
//= require "omega/station/interact"
//= require "omega/station/gfx"

Omega.Station = function(parameters){
  this.components = [];
  this.shader_components = [];
  this.resources  = [];
  $.extend(this, parameters);

  this.parent_id = this.system_id;
  this.location = Omega.convert_entity(this.location)
  this._update_resources();
};

Omega.Station.prototype = {
  constructor: Omega.Station,
  json_class : 'Manufactured::Station',

  belongs_to_user : function(user_id){
    return this.user_id == user_id;
  },

  alive : function(){
    /// XXX interim compatability hack
    return true;
  },

  update_system : function(new_system){
    this.solar_system = new_system;
    if(new_system){
      this.system_id    = new_system.id;
      this.parent_id    = new_system.id;
    }
  },

  in_system : function(system_id){
    return this.system_id == system_id;
  },

  _update_resources : function(){
    if(this.resources){
      for(var r = 0; r < this.resources.length; r++){
        var res = this.resources[r];
        if(res.data)  $.extend(res, res.data);
      }
    }
  },

  has_details : true,

  selected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0);
  },

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  construction_bar_props : {
    length: 200
  },

  async_gfx : 2,

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Station.gfx)            === 'undefined') Omega.Station.gfx = {};
    if(typeof(Omega.Station.gfx[this.type]) !== 'undefined') return;
    Omega.load_station_gfx(config, this.type, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_station_gfx(config, this, event_cb);
  },

  cp_gfx : function(from){
    /// return if not initialized
    if(!from.components || from.components.length == 0) return;
    Omega.cp_station_gfx(from, this);
  },

  update_gfx : function(){
    if(!this.location) return;
    Omega.update_station_gfx(this);
  },
};

Omega.UI.ResourceLoader.prototype.apply( Omega.Station.prototype );
$.extend(Omega.Station.prototype, Omega.StationCommands);
$.extend(Omega.Station.prototype, Omega.StationInteraction);
$.extend(Omega.Station.prototype, Omega.StationGfxUpdaters);
$.extend(Omega.Station.prototype, Omega.StationEffectRunner);
///

// Return stations owned by the specified user
Omega.Station.owned_by = function(user_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Station', 'owned_by', user_id,
    function(response){
      var stations = [];
      if(response.result)
        for(var e = 0; e < response.result.length; e++)
          stations.push(new Omega.Station(response.result[e]));
      if(cb) cb(stations);
    });
}

// Returns stations in the specified system
Omega.Station.under = function(system_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Station', 'under', system_id,
    function(response){
      var stations = [];
      if(response.result)
        for(var s = 0; s < response.result.length; s++)
          stations.push(new Omega.Station(response.result[s]));
      if(cb) cb(stations);
    });
};
