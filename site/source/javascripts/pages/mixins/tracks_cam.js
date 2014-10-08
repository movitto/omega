/* Omega Page Tracks Cam Mixin
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 * Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

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
    this.set_cam_mode();
  },


  _set_entity_scales : function(){
    var children      = this.canvas.root ? this.canvas.root.children : [];
    var manu_entities = this.manu_entities();
    var entities      = children.concat(manu_entities);
    for(var e = 0; e < entities.length; e++)
      this._set_entity_scale(entities[e]);
  },

  _set_entity_scale : function(entity){
    entity.scale_position(this.scene_scale);
  },

  _set_entity_modes : function(){
    var manu_entities = this.manu_entities();
    for(var e = 0; e < manu_entities.length; e++)
      this._set_entity_mode(manu_entities[e]);
  },

  _set_entity_mode : function(entity){
    /// TODO group nearby sprites
    /// TODO detect if camera is in 'vicinity' of entity, set mode to that if so
    if(entity.mode != this._cam_mode){
      if(entity.in_scene()){
        var _this = this;
        this.canvas.reload(entity, function(){
          entity.set_mode(_this._cam_mode);
        });

      }else{
        entity.set_mode(this._cam_mode);
      }
    }
  },

  set_cam_mode : function(){
    var percent  = this._cam_percent();
    var far      = Omega.Config.cam.distance.far;
    var near     = Omega.Config.cam.distance.near;

    if(percent > far){
      this._cam_mode = "far";
      this._far_cam_mode();

    }else if(percent > near){
      this._cam_mode = "mid";
      this._mid_cam_mode();

    }else{
      this._cam_mode = "near";
      this._near_cam_mode();
    }
  },

  _far_cam_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    this.scene_scale = Omega.Config.position_scales.system.max;

    this._set_entity_scales();
    this._set_entity_modes();
  },

  _mid_cam_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    /// scale from system_scale -> 1 as cam distance decreases
    /// will be a bit of a jump at boundry as percent is not
    /// being converted to proportion of near/far cam range
    /// (keeping for now as it is a good effect)
    var percent = this._cam_percent();
    var max     = Omega.Config.position_scales.system.max;
    var min     = Omega.Config.position_scales.system.min;
    this.scene_scale = percent * (max - min) + min;

    this._set_entity_scales();
    this._set_entity_modes();
  },

  _near_cam_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    this.scene_scale = Omega.Config.position_scales.system.min;

    this._set_entity_scales();
    this._set_entity_modes();
  },

  _sync_entity_with_cam : function(entity){
    this._set_entity_scale(entity);
    this._set_entity_mode(entity);
  }
};
