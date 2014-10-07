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
    this.set_entity_scales();
  },

  _entities_to_scale : function(){
    var children = this.canvas.root ? this.canvas.root.children : [];
    var manu_entities = this.manu_entities();
    return children.concat(manu_entities);
  },

  _set_scales : function(scale){
    var entities = this._entities_to_scale();
    for(var e = 0; e < entities.length; e++)
      if(entities[e].scale_position)
        entities[e].scale_position(scale);
  },

  set_entity_scales : function(){
    var percent  = this._cam_percent();
    var far      = Omega.Config.cam.distance.far;
    var near     = Omega.Config.cam.distance.near;

    if(percent > far){
      this._far_cam_mode();
      this._cam_mode = "far";

    }else if(percent > near){
      this._mid_cam_mode();
      this._cam_mode = "mid";

    }else{
      this._near_cam_mode();
      this._cam_mode = "near";
    }
  },

  _far_cam_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    this.scene_scale = Omega.Config.scale_system;
    this._set_scales(this.scene_scale);
/// TODO render manu entities as sprites
  },

  _mid_cam_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    /// scale from system_scale -> 1 as cam distance decreases
    /// will be a bit of a jump at boundry as percent is not
    /// being converted to proportion of near/far cam range
    /// (keeping for now as it is a good effect)
    var percent = this._cam_percent();
/// FIXME min scale from config (and below)
    this.scene_scale   = percent * (9*Omega.Config.scale_system/10) + Omega.Config.scale_system/10;
    this._set_scales(this.scene_scale);
/// TODO render manu entities as sprites (grouping nearby units)
  },

  _near_cam_mode : function(){
    if(this.canvas.root && this.canvas.root.json_class != 'Cosmos::Entities::SolarSystem') return;

    this.scene_scale = Omega.Config.scale_system/10;
    this._set_scales(this.scene_scale);
  }
};
