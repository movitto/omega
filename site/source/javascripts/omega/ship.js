/* Omega Ship JS Representation
 *
 * Copyright (C) 2013-2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "omega/ship/commands"
//= require "omega/ship/interact"
//= require "omega/ship/gfx"
//= require "omega/ship/movement"

//= require "omega/ship/attack/target"

///
Omega.Ship = function(parameters){
  this.components = [];
  this.shader_components = [];
  this.resources = [];
  $.extend(this, parameters);

  this.parent_id = this.system_id;
  this.location = Omega.convert.entity(this.location)
  this._update_resources();
  this._update_weapons_class();
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
     var cloned = new Omega.Ship();
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

  /// Return bool indicating if ship is mining
  is_mining : function(){
    return !!(this.mining);
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
        if(res.data) $.extend(res, res.data);
      }
    }
  },

  _update_weapons_class : function(){
    this.weapons_class = Omega.Constraint.gen('ship', 'weapons_classes', this.type);
  },

  /// TODO should be 'weapons_class_scale' (type comes after scale in weapons_class)
  weapons_class_type : function(){
    if(!this.weapons_class) return "";
    return this.weapons_class.substr(0, 5);
  },

  added_to : function(canvas, scene){
    /// XXX store canvas / scene for later usage
    this.canvas = canvas;
    this.scene  = scene;
  },

  /// trigger canvas reload
  //
  /// XXX don't like having this at this level, will be looking
  ///  to refactor this at some point at some point
  reload_in_scene : function(cb){
    this.canvas.reload(this, this.scene, cb);
  },

  removed_from : function(canvas, scene){
    this.canvas = null;
    this.scene  = null;
  },

  clicked_in : function(canvas){
    canvas.page.audio_controls.play(canvas.page.audio_controls.effects.click);
    canvas.follow_entity(this);
  },

  selected : function(page){
    if(this.is_mining())
      page.audio_controls.play(this.mining_audio);
    else if(!this.location.is_stopped())
      page.audio_controls.play(this.movement_audio);

    this.mesh.tmesh.material.emissive.setHex(0xff0000);
  },

  unselected : function(page){
    page.audio_controls.stop([this.mining_audio, this.movement_audio]);

    this.mesh.tmesh.material.emissive.setHex(0);
  }
};

THREE.EventDispatcher.prototype.apply( Omega.Ship.prototype );
$.extend(Omega.Ship.prototype, Omega.ShipCommands);
$.extend(Omega.Ship.prototype, Omega.ShipInteraction);
$.extend(Omega.Ship.prototype, Omega.ShipGfx);
$.extend(Omega.Ship.prototype, Omega.ShipMovement);
$.extend(Omega.Ship.prototype, Omega.ShipAttackTarget);
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
