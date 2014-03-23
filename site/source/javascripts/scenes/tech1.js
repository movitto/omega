/* Omega Tech Demo 1 Scene
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3+ http://www.gnu.org/licenses/agpl.txt
 */

//= require "scenes/common"
//= require "scenes/tech1/audio"
//= require "scenes/tech1/setting"

Omega.Scenes.Tech1 = function(config){
  this.audio   = new Omega.Scenes.Tech1Audio(config);
  this.setting = new Omega.Scenes.Tech1Setting(config);
};

Omega.Scenes.Tech1.prototype = {
  id : 'tech1',

  /// initialize scene camera
  _init_cam : function(page){
    page.canvas.cam.position.set(2500, 2500, -2500);
    page.canvas.focus_on({x: 0, y: 0, z: 0});
  },

  /// setup scene components
  _setup_scene : function(page){
    page.canvas.set_scene_root(this.setting.system);
    var scene_components = this.setting.scene_components();
    for(var s = 0; s < scene_components.length; s++){
      page.canvas.add(scene_components[s]);
    }

    this.setting.skybox.set(2, Omega.Config,
      Omega.UI.Canvas.trigger_animation(page.canvas))
  },

  /// camera zoom timer callback
  _zoom_cam : function(page){
    var _this = this;

    /// tgt camera focus / position is behind ship group
    var loc = this.setting.ships[0].location;
    var tgt_pos = new Omega.Location().set(loc.sub(500, -300, 500));

    Omega.SceneEffects.transition_camera(page.canvas, tgt_pos, 20, function(dir){
      page.canvas.cam.position.set(tgt_pos.x, tgt_pos.y, tgt_pos.z);
      _this.zoom_cam.stop();
      _this.orbit_cam.play();
    });

    /// keep cam focused on loc
    page.canvas.focus_on(loc);
  },

  _orbit_cam : function(page){
    var loc = this.setting.ships[0].location;

    page.canvas.cam_controls.autoRotate = true;
    page.canvas.cam_controls.autoRotateSpeed = -3.0;

    /// keep cam focused on loc
    page.canvas.focus_on(loc);
  },

  /// create effect timers
  _create_timers : function(page){
    var _this = this;

    this.zoom_cam = $.timer(function(){
      _this._zoom_cam(page);
    }, 5, false);

    this.orbit_cam = $.timer(function(){
      _this._orbit_cam(page);
    }, 5, false);
  },

  /// run scene
  run : function(page){
    this._init_cam(page);
    this._setup_scene(page);
    this._create_timers(page);

    page.audio_controls.play(this.audio);
    this.zoom_cam.play();
  },

  /// stop scene
  stop : function(page){
    if(this.zoom_cam)  this.zoom_cam.stop();
    if(this.orbit_cam) this.orbit_cam.stop();
    page.audio_controls.stop();
    page.canvas.clear();
  }
};
