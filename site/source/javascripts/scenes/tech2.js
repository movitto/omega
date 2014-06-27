/* Omega Tech Demo 2 Scene
 *
 * Copyright (C) 2014 Mohammed Morsi <mo@morsi.org>
 *  Licensed under the AGPLv3 http://www.gnu.org/licenses/agpl.txt
 */

//= require "scenes/common"
//= require "scenes/tech2/setting"

Omega.Scenes.Tech2 = function(config){
  this.setting = new Omega.Scenes.Tech2Setting(config);
};

Omega.Scenes.Tech2.prototype = {
  id : 'tech2',

  /// load scene components
  _load_scene : function(page, cb){
    this.setting.load(page.config, cb);
  },

  /// setup scene components
  _setup_scene : function(page){
    page.canvas.set_scene_root(this.setting.system);
    page.canvas.add(this.setting.skybox, page.canvas.skyScene);

    this.setting.skybox.set(1, Omega.Config,
      Omega.UI.Canvas.trigger_animation(page.canvas))
  },

  /// initialize scene camera
  _init_cam : function(page){
    var follow = this.setting.ships[1];
    page.canvas.follow(follow.position_tracker());
    page.canvas.cam.position.divideScalar(3);
    page.canvas.cam_controls.update();
  },

  start_orbit : function(page){
    page.canvas.cam_controls.autoRotate = true;
    page.canvas.cam_controls.autoRotateSpeed = -3.0;
  },

  change_strategies : function(){
    for(var s = 0; s < this.setting.ships.length; s++){
      var ax = Math.random();
      var ay = Math.random();
      var az = Math.random();
      var nrml = Omega.Math.nrml(ax, ay, az);
      ax = nrml[0]; ay = nrml[1]; az = nrml[2];

      var angle = Math.random() * Math.PI;

      var ship = this.setting.ships[s];
      ship.new_strategy = {ax : ax, ay : ay, az : az,
                           angle : angle, current_angle : 0};
    }
  },

  adjust_strategies : function(){
    var delta = 0.1;

    for(var s = 0; s < this.setting.ships.length; s++){
      var ship = this.setting.ships[s];
      if(!ship.new_strategy ||
          ship.new_strategy.current_angle >= ship.new_strategy.angle) return;

      var updated = Omega.Math.rot(ship.location.movement_strategy.dx,
                                   ship.location.movement_strategy.dy,
                                   ship.location.movement_strategy.dz,
                                   delta,
                                   ship.new_strategy.ax,
                                   ship.new_strategy.ay,
                                   ship.new_strategy.az);

      ship.location.movement_strategy.dx = ship.location.orientation_x = updated[0];
      ship.location.movement_strategy.dy = ship.location.orientation_y = updated[1];
      ship.location.movement_strategy.dz = ship.location.orientation_z = updated[2];

      ship.new_strategy.current_angle += delta;
    }
  },

  /// create effect timers
  _create_timers : function(page){
    var _this = this;

    this.effects_timer = $.timer(function(){
      page.canvas.cam_controls.update();
      _this.adjust_strategies();
    }, Omega.UI.EffectsPlayer.prototype.interval, false);

    this.strategy_timer = $.timer(function(){
      _this.change_strategies();
    }, 10000, false);
  },

  /// run scene
  run : function(page){
    var _this = this;
    this._load_scene(page, function(){
      _this._setup_scene(page);
      _this._init_cam(page);
      _this.start_orbit(page);
      _this._create_timers(page);

      _this.effects_timer.play();
      _this.strategy_timer.play();
    });
  },

  /// stop scene
  stop : function(page){
    if(this.effects_timer) this.effects_timer.stop();
    if(this.strategy_timer) this.strategy_timer.stop();
    page.canvas.clear();
  }
};
