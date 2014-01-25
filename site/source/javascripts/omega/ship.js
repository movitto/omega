/* Omega Ship JS Representation
 *
 * Copyright (C) 2013 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/commands"
//= require "omega/ship/interact"
//= require "omega/ship/gfx"

Omega.Ship = function(parameters){
  this.components = [];
  this.shader_components = [];
  this.resources = [];
  $.extend(this, parameters);

  this.parent_id = this.system_id;
  this.location = Omega.convert_entity(this.location)
  this._update_resources();
};

Omega.Ship.prototype = {
  constructor: Omega.Ship,

  json_class : 'Manufactured::Ship',

  /// see omega/ship/commands.js for retrieve_details implementation
  has_details : true,

  highlight_props : {
    x     :    0, y     : 200, z     : 0,
    rot_x : 3.14, rot_y :   0, rot_z : 0
  },

  trail_props : {
    plane : 3, lifespan : 20
  },

  health_bar_props : {
    length : 200
  },

  debug_gfx : false,

  /// template mesh, mesh, and particle texture
  async_gfx : 3,

  belongs_to_user : function(user_id){
    return this.user_id == user_id;
  },

  alive : function(){
    return this.hp > 0;
  },

  update_system : function(new_system){
    this.solar_system   = new_system;
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

  clicked_in : function(canvas){
    if(canvas.page.audio_controls)
      canvas.page.audio_controls.play('click');
  },

  selected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    if(this.mesh) this.mesh.material.emissive.setHex(0);
  },

  load_gfx : function(config, event_cb){
    if(typeof(Omega.Ship.gfx)            === 'undefined') Omega.Ship.gfx = {};
    if(typeof(Omega.Ship.gfx[this.type]) !== 'undefined') return;
    Omega.load_ship_gfx(config, this.type, event_cb);
  },

  init_gfx : function(config, event_cb){
    if(this.components.length > 0) return; /// return if already initialized
    this.load_gfx(config, event_cb);
    Omega.init_ship_gfx(config, this, event_cb);
  },

  cp_gfx : function(from){
    /// return if not initialized
    if(!from.components || from.components.length == 0) return;
    Omega.cp_ship_gfx(from, this);
  },

  update_gfx : function(){
    if(!this.location) return;
    Omega.update_ship_gfx(this);
  },
};

Omega.UI.ResourceLoader.prototype.apply( Omega.Ship.prototype );
$.extend(Omega.Ship.prototype, Omega.ShipCommands);
$.extend(Omega.Ship.prototype, Omega.ShipInteraction);
$.extend(Omega.Ship.prototype, Omega.ShipGfxUpdaters);
$.extend(Omega.Ship.prototype, Omega.ShipEffectRunner);
///

// Return ship with the specified id
Omega.Ship.get = function(ship_id, node, cb){
  node.http_invoke('manufactured::get_entity', 'with_id', ship_id,
    function(response){
      var ship = null;
      var err  = null;
      if(response.result)
        ship = new Omega.Ship(response.result);
      else if(response.error)
        err = response.error.message;
      if(cb) cb(ship, err);
    });
}

// Return ships owned by the specified user
Omega.Ship.owned_by = function(user_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Ship', 'owned_by', user_id,
    function(response){
      var ships = [];
      if(response.result)
        for(var e = 0; e < response.result.length; e++)
          ships.push(new Omega.Ship(response.result[e]));
      if(cb) cb(ships);
    });
}

// Returns ships in the specified system
Omega.Ship.under = function(system_id, node, cb){
  node.http_invoke('manufactured::get_entities',
    'of_type', 'Manufactured::Ship', 'under', system_id,
    function(response){
      var ships = [];
      if(response.result)
        for(var s = 0; s < response.result.length; s++)
          ships.push(new Omega.Ship(response.result[s]));
      if(cb) cb(ships);
    });
};
