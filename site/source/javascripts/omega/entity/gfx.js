/* Omega Base Entity Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// Base Entity GFX Mixin
Omega.EntityGfx = {
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

  // Return graphics tracker for local entity class & optional
  // specified type, initializing if it doesn't exist
  _gfx_tracker : function(type){
    if(typeof(Omega.EntityGfx._tracker) == "undefined")
      Omega.EntityGfx._tracker = {};
    var gfx = Omega.EntityGfx._tracker;

    var no_type = typeof(type) === "undefined";
    if(typeof(gfx[this.json_class]) == "undefined"){
      if(no_type)
        gfx[this.json_class] = false;
      else
        gfx[this.json_class] = {type : false}

    }else if(!no_type && typeof(gfx[this.json_class][type]) == "undefined")
      gfx[this.json_class][type] = false;

    return gfx;
  },

  /// True / false if entity gfx have been preloaded
  gfx_loaded : function(type){
    var gfx = this._gfx_tracker(type);
    if(typeof(type) == "undefined")
      return !!(gfx[this.json_class]);
    return !!(gfx[this.json_class][type]);
  },

  // Set loaded_gfx true
  _loaded_gfx : function(type){
    var gfx = this._gfx_tracker(type);
    if(typeof(type) == "undefined")
      gfx[this.json_class] = true;
    else
      gfx[this.json_class][type] = true;
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
