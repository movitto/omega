/* Omega Page Tracks Cam Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

/// TODO scale indicator size so they are always a fixed size
/// upgrade three.js ? http://stackoverflow.com/questions/20396150/three-js-how-to-keep-sprite-text-size-unchanged-when-zooming
/// (only in far mode? scale w/ camera distance in near mode?)

Omega.Pages.TracksCam = {
  track_cam : function(){
    var _this = this;
    this.canvas.cam_controls.addEventListener('change', function(){
      _this._cam_change();
    })
  },

  _cam_percent : function(){
    var distance = this.canvas.cam.position.clone().sub(this.canvas.cam_controls.target).length();
    return distance / Omega.Config.cam.distance.max;
  },

  _cam_change : function(){
    this.set_scene_mode();
  },

  _scale_entities : function(){
    var children      = this.canvas.root ? this.canvas.root.children : [];
    var manu_entities = this.manu_entities();
    var entities      = children.concat(manu_entities);
    for(var e = 0; e < entities.length; e++)
      this._scale_entity(entities[e]);
  },

  _scale_entity : function(entity){
    entity.scale_position(this.scene_scale);
    entity.scale_size(this.entity_scale);
  },

  _set_entity_modes : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    var children      = this.canvas.root ? this.canvas.root.children : [];
    var manu_entities = this.manu_entities();
    var entities      = children.concat(manu_entities);
    for(var e = 0; e < entities.length; e++)
      this._set_entity_mode(entities[e]);
  },

  _set_entity_mode : function(entity){
    if(entity.scene_mode != this._scene_mode){
      var _this = this;
      this.canvas.reload_in_all(entity, function(){
        entity.set_scene_mode(_this._scene_mode);
      });
    }
  },

  set_scene_mode : function(){
    var percent  = this._cam_percent();
    var far      = Omega.Config.cam.distance.far;
    var near     = Omega.Config.cam.distance.near;

    if(percent > far){
      this._scene_mode = "far";
      this._far_scene_mode();

    }else if(percent > near){
      this._scene_mode = "mid";
      this._mid_scene_mode();

    }else{
      this._scene_mode = "near";
      this._near_scene_mode();
    }
  },

  _far_scene_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    this.scene_scale  = Omega.Config.position_scales.system.far;
    this.entity_scale = Omega.Config.entity_scales.system.far;

    this._scale_entities();
    this._set_entity_modes();
  },

  _mid_scene_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    /// scale from max -> min as cam distance decreases.
    /// there will be a bit of a jump at boundry as percent is not
    /// being converted to proportion of near/far cam range
    /// (keeping for now as it is a good effect)
    var percent = this._cam_percent();
    var maxp    = Omega.Config.position_scales.system.max;
    var minp    = Omega.Config.position_scales.system.min;
    this.scene_scale = percent * (maxp - minp) + minp;

    var maxe    = Omega.Config.entity_scales.system.max;
    var mine    = Omega.Config.entity_scales.system.min;
    this.entity_scale = mine - percent * (mine - maxe);
    //this.entity_scale = percent * (mine - maxe) + maxe;

    this._scale_entities();
    this._set_entity_modes();
  },

  _near_scene_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    this.scene_scale  = Omega.Config.position_scales.system.min;
    this.entity_scale = Omega.Config.entity_scales.system.min;

    this._scale_entities();
    this._set_entity_modes();
  },

  _sync_entity_with_cam : function(entity){
    this._scale_entity(entity);
    this._set_entity_mode(entity);
  }
};
