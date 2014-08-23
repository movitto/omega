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

  // Return tracker used to manage load states,
  // initializing it if it doesn't exist
  _loaded_tracker : function(){
    var tracker = Omega.UI.CanvasEntityGfx.__loaded_tracker =
                  Omega.UI.CanvasEntityGfx.__loaded_tracker || {};

    if(this._has_type()){
      tracker[this.json_class]            = tracker[this.json_class] || {};
      tracker[this.json_class][this.type] = tracker[this.json_class][this.type] || false;

    }else{
      tracker[this.json_class]            = tracker[this.json_class] || false;
    }

    return tracker;
  },

  // Return tracker used to manage resource states,
  // initializing it if it doesn't exist
  _resource_tracker : function(){
    var tracker = Omega.UI.CanvasEntityGfx.__resource_tracker =
                  Omega.UI.CanvasEntityGfx.__resource_tracker || {};

    if(this._has_type()){
      tracker[this.json_class]            = tracker[this.json_class] || {};
      tracker[this.json_class][this.type] = tracker[this.json_class][this.type] || {};

    }else{
      tracker[this.json_class]            = tracker[this.json_class] || {};
    }

    return tracker;
  },

  /// True / false if entity gfx have been preloaded
  gfx_loaded : function(){
    var loaded = this._loaded_tracker();
    return this._no_type() ? !!(loaded[this.json_class]) :
                             !!(loaded[this.json_class][this.type]);
  },

  // Set loaded_gfx true
  _loaded_gfx : function(){
    var loaded = this._loaded_tracker();
    if(this._no_type())
      loaded[this.json_class] = true;
    else
      loaded[this.json_class][this.type] = true;
  },

  /// store specified resource
  _store_resource : function(id, resource){
    var resources = this._resource_tracker()[this.json_class];
    if(this._has_type()) resources[this.type][id] = resource;
    else resources[id] = resource;
  },

  /// retrieve specified resource
  _retrieve_resource : function(id){
    var resources = this._resource_tracker()[this.json_class];
    if(this._has_type()) return resources[this.type][id];
    return resources[id];
  },

  /// load specified async resource
  _load_async_resource : function(id, resource, cb){
    Omega.UI.AsyncResourceLoader.load(id, resource, cb);
  },

  /// retrieve specified async resource
  _retrieve_async_resource : function(id, cb){
    return Omega.UI.AsyncResourceLoader.retrieve(id, cb);
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
