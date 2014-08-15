/* Omega Base Canvas Entity Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// Base Canvas Entity GFX Mixin
Omega.UI.CanvasEntityGfx = {
  /// Returns location which to render gfx components, overridable
  scene_location : function(){
    return this.location;
  },

  /// Returns position tracker, 3D object automatically update w/ entity position
  position_tracker : function(){
    if(!this._position_tracker)
      this._position_tracker = new THREE.Object3D();
    return this._position_tracker;
  },

  // Returns 3D object tracking ship location
  location_tracker : function(){
    if(!this._location_tracker)
      this._location_tracker = new THREE.Object3D();
    return this._location_tracker;
  },

  _has_type : function(){
    return !!(this.type);
  },

  _no_type : function(){
    return !this._has_type();
  },

  // Return graphics tracker for local entity class & optional type,
  // initializing if it doesn't exist
  _gfx_tracker : function(){
    var gfx = Omega.UI.CanvasEntityGfx._tracker =
              Omega.UI.CanvasEntityGfx._tracker ||
              {loaded : {}, resources : {}};

    if(this._has_type()){
      gfx['loaded'][this.json_class]               = gfx['loaded'][this.json_class] || {};
      gfx['loaded'][this.json_class][this.type]    = gfx['loaded'][this.json_class][this.type] || false;
      gfx['resources'][this.json_class]            = gfx['resources'][this.json_class] || {};
      gfx['resources'][this.json_class][this.type] = gfx['resources'][this.json_class][this.type] || {};

    }else{
      gfx['loaded'][this.json_class]               = gfx['loaded'][this.json_class] || false;
      gfx['resources'][this.json_class]            = gfx['resources'][this.json_class] || {};
    }

    return gfx;
  },

  /// True / false if entity gfx have been preloaded
  gfx_loaded : function(){
    var gfx = this._gfx_tracker();
    if(this._no_type())
      return !!(gfx['loaded'][this.json_class]);
    return !!(gfx['loaded'][this.json_class][this.type]);
  },

  // Set loaded_gfx true
  _loaded_gfx : function(){
    var gfx = this._gfx_tracker();
    if(this._no_type())
      gfx['loaded'][this.json_class] = true;
    else
      gfx['loaded'][this.json_class][this.type] = true;
  },

  /// store specified resource
  _store_resource : function(id, resource){
    var gfx = this._gfx_tracker()['resources'][this.json_class];
    if(this._has_type()) gfx[this.type][id] = resource;
    else gfx[id] = resource;
  },

  /// retrieve specified resource
  _retrieve_resource : function(id){
    var gfx = this._gfx_tracker()['resources'][this.json_class];
    if(this._has_type()) return gfx[this.type][id];
    return gfx[id];
  },

  /// True / false if gfx have been initialized
  gfx_initialized : function(){
    return !!(this._gfx_initialized);
  },

  /// True / false if gfx are being initialized
  gfx_initializing : function(){
    return !this.gfx_initialized() && !!(this._gfx_initializing);
  },

  /// True / false if entity has effects
  has_effects : function(){
    return !!(this.run_effects);
  }
}; // Omega.EntityGfx

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasEntityGfx );
