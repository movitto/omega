/* Omega Ship JS Representation
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/commands"
//= require "omega/ship/interact"
//= require "omega/ship/gfx"

///
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

  /// Update ship's mutable properties from other
  update : function(ship){
    this.hp             = ship.hp;
    this.shield_level   = ship.shield_level;
    this.distance_moved = ship.distance_moved;
    this.docked_at_id   = ship.docked_at_id;
    this.attacking_id   = ship.attacking_id;
    this.mining         = ship.mining;
    this.resources      = ship.resources;
    this.system_id = this.parent_id = ship.system_id;
    this.location.update(ship.location);
  },

  /// Return clone of this ship
  clone : function(){
     var cloned = new Omega.Location();
     return $.extend(true, cloned, this); /// deep copy
  },

  /// Return bool indicating if ship belongs to the specified user
  belongs_to_user : function(user_id){
    return this.user_id == user_id;
  },

  /// Return bool indicating if ship is alive
  alive : function(){
    return this.hp > 0;
  },

  /// HP percentage
  hpp : function(){
    return this.hp / this.max_hp;
  },

  /// Update this ship's system
  update_system : function(new_system){
    this.solar_system   = new_system;
    if(new_system){
      this.system_id    = new_system.id;
      this.parent_id    = new_system.id;
    }
  },

  /// Return bool indicating if ship is in the specified system
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
    if(this.mesh && this.mesh.tmesh)
      this.mesh.tmesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    if(this.mesh && this.mesh.tmesh)
      this.mesh.tmesh.material.emissive.setHex(0);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Ship.prototype );
Omega.UI.ResourceLoader.prototype.apply( Omega.Ship.prototype );
$.extend(Omega.Ship.prototype, Omega.ShipCommands);
$.extend(Omega.Ship.prototype, Omega.ShipInteraction);
$.extend(Omega.Ship.prototype, Omega.ShipGfx);
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
