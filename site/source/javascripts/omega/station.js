/* Omega Station JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require 'ui/canvas/components/orbit'
//= require "omega/station/commands"
//= require "omega/station/interact"
//= require "omega/station/gfx"

Omega.Station = function(parameters){
  this.components = [];
  this.resources  = [];
  $.extend(this, parameters);

  this.parent_id = this.system_id;
  this.location = Omega.convert.entity(this.location)
  this._update_resources();
};

Omega.Station.prototype = {
  constructor: Omega.Station,
  json_class : 'Manufactured::Station',

  /// Update station's properties from other
  update : function(station){
    this.resources = station.resources;
    this.system_id = this.parent_id = station.system_id;
    this.location.update(station.location);
  },

  /// Return bool indicating if station belongs to the specified user
  belongs_to_user : function(user_id){
    return this.user_id == user_id;
  },

  /// Return bool indicating if station is alive
  alive : function(){
    /// XXX interim compatability hack
    return true;
  },

  /// Return bool indicating if station is constructing
  is_constructing : function(){
    return !!(this._constructing);
  },

  /// Update this station's system
  update_system : function(new_system){
    this.solar_system = new_system;
    if(new_system){
      this.system_id    = new_system.id;
      this.parent_id    = new_system.id;
    }
  },

  /// Return bool indicating if station is in the specified system
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

  clicked_in : function(canvas){
    var ac = canvas.page.audio_controls;
    ac.play(ac.effects.click);
    canvas.follow_entity(this);
  },

  selected : function(page){
    if(this.is_constructing())
      page.audio_controls.play(this.construction_audio, 'started');
    this.mesh.tmesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    this.mesh.tmesh.material.emissive.setHex(0);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Station.prototype );
$.extend(Omega.Station.prototype, Omega.StationCommands);
$.extend(Omega.Station.prototype, Omega.StationInteraction);
$.extend(Omega.Station.prototype, Omega.StationGfx);
$.extend(Omega.Station.prototype, Omega.OrbitHelpers);
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
