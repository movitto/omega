/* Omega Base Canvas Entity Graphics
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

// Base Canvas Entity GFX Mixin
Omega.UI.CanvasEntityGfx = {
  /// Return scene components, by default components array
  scene_components : function(scene){
    return this.components;
  },

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

  // Returns 3D object tracking entity location
  location_tracker : function(){
    if(!this._location_tracker)
      this._location_tracker = new THREE.Object3D();
    return this._location_tracker;
  },

  // Returns 3D object used to track camera
  camera_tracker : function(){
    if(!this._camera_tracker){
      this._camera_tracker = new THREE.Object3D();
      this._camera_tracker.position = this.position_tracker().position;

      if(this.orient_camera){
        /// XXX quaternion ultimately controls rotation, keeping those in sync here
        //this._camera_tracker.rotation = this.location_tracker().rotation;
	      this._camera_tracker.quaternion = this.location_tracker().quaternion;
      }
    }
    return this._camera_tracker;
  },

  /// scaled scene location
  _scaled_scene_location : function(){
    /// TODO caching scene loc w/ invalidation mechanism
    return this.location.clone().set(this.location.divide(this.scene_scale));
  },

  /// scale position
  scale_position : function(scale){
    if(!this._scene_location) this._scene_location = this.scene_location;
    this.scene_scale = scale;
    this.scene_location = this._scaled_scene_location;

    /// XXX need to also scale other components
    if(this.orbit) this.orbit_line.line.scale.set(1/scale, 1/scale, 1/scale);
    if(this.selection) this.selection.tmesh.scale.set(1/scale, 1/scale, 1/scale);

    if(this.gfx_initialized()) this.update_gfx();
  },

  /// unscale position
  unscale_position : function(){
    if(this._scene_location){
      this.scene_location  = this._scene_location;
      this._scene_location = null;
    }

    this.scene_scale = null;
    if(this.orbit) this.orbit_line.line.scale.set(1, 1, 1);
    if(this.selection) this.selection.tmesh.scale.set(1, 1, 1);
  },

  _has_type : function(){
    return typeof(this.type) !== "undefined";
  },

  _no_type : function(){
    return !this._has_type();
  },

  /// Set scene mode
  set_scene_mode : function(scene_mode){
    this.scene_mode = scene_mode;
    if(this.gfx_initialized()) this.update_gfx();
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
  },

  /// Default callback invoked by canvas when entity is added to scene
  added_to : function(canvas, scene){
    /// XXX store canvas / scene for later usage
    this.canvas = canvas;
    this.scene  = scene;
  },

  /// Trigger a canvas reload
  reload_in_scene : function(cb){
    this.canvas.reload(this, this.scene, cb);
  },

  /// Default callback invoked by canvas when entity is removed from scene
  removed_from : function(canvas, scene){
    this.canvas = null;
    this.scene  = null;
  },

  /// Return boolean indicating if entity is in scene
  in_scene : function(){
    return !!(this.canvas) && !!(this.scene);
  },

  /// Takes callback which updates components, invokes it via a scene
  /// reload if entity is in scene else just invokes
  update_components : function(cb){
    /// TODO more targeted update, just detect changes in entity components array
    /// and add / remove those scene components accordingly
    if(this.in_scene())
      this.reload_in_scene(cb);
    else
      cb();
  }
}; // Omega.EntityGfx

THREE.EventDispatcher.prototype.apply( Omega.UI.CanvasEntityGfx );
